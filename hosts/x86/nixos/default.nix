{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Hardware ##
    inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-ssd

    ## Required Configs ##
    (lib.custom.scanPaths ./.)

    (lib.custom.relativeToRoot "modules/nixos/core") # sets up core nixos configuration

    ## Optional Configs ##
    # (lib.custom.relativeToRoot "modules/nixos/services/ai.nix") # sets up llama-cpp and related tools
    (lib.custom.relativeToRoot "modules/nixos/hardware/audio.nix") # pipewire and cli controls
    (lib.custom.relativeToRoot "modules/nixos/services/ddcutil.nix") # ddcutil for monitor controls
    (lib.custom.relativeToRoot "modules/nixos/services/plymouth.nix") # fancy boot screen
    (lib.custom.relativeToRoot "modules/nixos/services/gaming") # steam, gamescope, gamemode, and related hardware

  ];

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
