{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  customLib = import (self.outPath + "/lib") { inherit lib; };

  ARM_DARWIN = "aarch64-darwin";

  # read host-dirs under hosts/darwin
  readHosts = lib.attrNames (builtins.readDir (customLib.relativeToRoot "hosts/darwin"));

  # build one darwin host
  mkDarwinHost =
    hostName:
    let
      system = ARM_DARWIN;

      # Import and evaluate the data modules to extract configuration
      pkgs = import inputs.nixpkgs { inherit system; };

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

          # Import secret spec and implementation
          (customLib.relativeToRoot "modules/global/secret-spec.nix")
          (customLib.relativeToRoot "lib/secrets.nix")
        ];
        specialArgs = {
          inherit pkgs lib;
        };
      };

      # Extract both host and secrets from the single evaluation
      host = dataEval.config.hostSpec.${hostName} or { };
      secrets = dataEval.config.secretsSpec;
    in
    {
      "${hostName}" = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            host
            inputs
            secrets
            system
            ;
          outputs = self;
          lib = inputs.nixpkgs.lib.extend (
            # INFO: Extend lib with lib.custom; This approach allows lib.custom to propagate into hm
            self: super: {
              custom = import (customLib.relativeToRoot "lib") { inherit (inputs.nixpkgs) lib; };
            }
          );
        };
        modules = [
          { nixpkgs.overlays = [ self.overlays.default ]; }

          # Host-specific configuration
          (customLib.relativeToRoot "hosts/darwin/${hostName}")
        ];
      };
    };

  # Invoke mkDarwinHost for each host config declared under hosts/darwin
  mkDarwinHostConfigs = hosts: lib.foldl (acc: set: acc // set) { } (lib.map mkDarwinHost hosts);
in
{
  flake.darwinConfigurations = mkDarwinHostConfigs readHosts;
}
