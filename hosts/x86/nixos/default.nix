###############################################################
#
#  Haze - Cesar's Desktop
#  NixOS running on Ryzen 5 7600x, Radeon RX 7600, 32GB RAM
#
###############################################################

{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## NixOS Only ##
    inputs.chaotic.nixosModules.default
    ./config

    ## Hardware ##
    ./hardware.nix
    inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-ssd

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/audio.nix" # pipewire and cli controls
      "hosts/global/common/ddcutil.nix" # ddcutil for monitor controls
      "hosts/global/common/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/global/common/plymouth.nix" # fancy boot screen
      "hosts/global/common/gaming" # steam, gamescope, gamemode, and related hardware
    ])
  ];

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
