{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = lib.flatten [
    ## Required Configs ##
    (lib.custom.scanPaths ./.)

    (lib.custom.relativeToRoot "modules/nixos/core") # sets up core nixos configuration
  ];

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
