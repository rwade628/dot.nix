{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    inputs.nixos-wsl.nixosModules.wsl
    ## Hardware ##
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ## Required Configs ##
    (lib.custom.scanPaths ./.)

    (lib.custom.relativeToRoot "modules/nixos/core") # sets up core nixos configuration
  ];

  wsl = {
    enable = true;
    useWindowsDriver = true;
    defaultUser = "ryan";
  };

  networking = {
    enableIPv6 = false;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
