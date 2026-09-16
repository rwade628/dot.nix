{
  self,
  inputs,
  lib,
  ...
}:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

      # Get all package names from pkgs/ (a bare "foo.nix" file or a "foo/"
      # directory both become the overlay attribute "foo" via
      # lib.packagesFromDirectoryRecursive in modules/flake/overlays.nix)
      packageDirs = builtins.attrNames (builtins.readDir (customLib.relativeToRoot "pkgs"));
      packageNames = builtins.map (
        name: if lib.hasSuffix ".nix" name then lib.removeSuffix ".nix" name else name
      ) packageDirs;

      # Filter to only include names that resolved to an actual derivation.
      # Excludes e.g. wine-app-wrapper.nix, a builder *function* meant to be
      # called with app-specific args by other Nix code, not built directly.
      validPackages = builtins.filter (
        name: builtins.hasAttr name pkgs && lib.isDerivation pkgs.${name}
      ) packageNames;

      # Create a set with all the packages
      customPackages = builtins.listToAttrs (
        builtins.map (name: {
          inherit name;
          value = pkgs.${name};
        }) validPackages
      );
    in
    {
      packages = customPackages;
    };
}
