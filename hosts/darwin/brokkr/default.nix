{ lib, ... }:
{
  imports = lib.flatten [
    ## Required Configs ##
    (lib.custom.scanPaths ./.)

    (lib.custom.relativeToRoot "modules/darwin/core") # sets up core darwin configuration
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  # https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.stateVersion
  system.stateVersion = 5;
}
