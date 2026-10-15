{
  self,
  inputs,
  lib,
  ...
}:
let
  # Darwin evaluates against nixpkgs-darwin (see flake.nix), not the
  # nixos-unstable `nixpkgs` the NixOS hosts use.
  inherit (inputs.nixpkgs-darwin) lib;
  customLib = import (self.outPath + "/lib") { inherit lib; };

  ARM_DARWIN = "aarch64-darwin";

  # read host-dirs under hosts/darwin
  readHosts = lib.attrNames (builtins.readDir (customLib.relativeToRoot "hosts/darwin"));

  # build one darwin host. `hostSpec` is merged over this host's entry in
  # lib/hosts.nix - a Work wrapper flake uses it to supply the private
  # values (user.osName, user.gitIdentity) this public repo never contains.
  mkDarwinSystem =
    {
      hostName,
      hostSpec ? { },
    }:
    let
      system = ARM_DARWIN;

      # Import and evaluate the data modules to extract configuration
      pkgs = import inputs.nixpkgs-darwin { inherit system; };

      # Evaluate all data modules together (specs + implementations)
      dataEval = lib.evalModules {
        modules = [
          # Provide assertions option that evalModules expects
          {
            options.assertions = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              default = [ ];
            };
          }

          # Import host spec and implementation
          (customLib.relativeToRoot "modules/global/host-spec.nix")
          (customLib.relativeToRoot "lib/hosts.nix")
          { hostSpec.${hostName} = hostSpec; }
        ];
        specialArgs = {
          inherit pkgs lib;
        };
      };

      host = dataEval.config.hostSpec.${hostName} or { };
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit
          host
          inputs
          system
          ;
        outputs = self;
        lib = inputs.nixpkgs-darwin.lib.extend (
          # INFO: Extend lib with lib.custom; This approach allows lib.custom to propagate into hm
          self: super: {
            custom = import (customLib.relativeToRoot "lib") { inherit (inputs.nixpkgs-darwin) lib; };
          }
        );
      };
      modules = [
        { nixpkgs.overlays = [ self.overlays.default ]; }
        # Module only - no Darwin host consumes a secret yet, so there's no
        # analogue of modules/nixos/core/sops.nix wiring defaultSopsFile
        # here. Add one (plus hosts/darwin/<hostname>/secrets.yaml) when
        # idun needs its first sops-nix secret.
        inputs.sops-nix.darwinModules.sops

        # Host-specific configuration
        (customLib.relativeToRoot "hosts/darwin/${hostName}")
      ];
    };
in
{
  # flake.lib has no flake-parts option of its own, so without this declaration
  # the definitions here and in overlays.nix (compatShims) can't merge.
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  config.flake.darwinConfigurations = lib.genAttrs readHosts (
    hostName: mkDarwinSystem { inherit hostName; }
  );

  # Consumed by a Work wrapper flake - see docs/work-host-setup.md.
  config.flake.lib.mkDarwinSystem = mkDarwinSystem;
}
