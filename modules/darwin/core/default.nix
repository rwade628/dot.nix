{
  inputs,
  outputs,
  host,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    inputs.home-manager.darwinModules.home-manager
    (lib.custom.scanPaths ./.)

    (map lib.custom.relativeToRoot [
      "modules/global"
    ])
    inputs.catppuccin.darwinModules.catppuccin
  ];

  # Force home-manager to use global packages
  home-manager.useGlobalPkgs = true;
  # Install user packages to /etc/profiles per user
  home-manager.useUserPackages = true;
  # If there is a conflict file that is backed up, use this extension
  home-manager.backupFileExtension = "backup";

  ## Overlays ##
  nixpkgs = {
    overlays = [
      outputs.overlays.default
    ];
    config.allowUnfree = true;
  };

  ## Networking ##
  networking.hostName = lib.mkDefault host.network.hostName;
  networking.localHostName = lib.mkDefault host.network.hostName;
  networking.computerName = lib.mkDefault host.network.hostName;

  ## Localization ##
  time.timeZone = lib.mkDefault "America/New_York";

  ## Primary shell enablement ##
  programs.zsh.enable = true;
  environment.shells = with pkgs; [
    zsh
    bash
  ];

  catppuccin = {
    enable = true;
    autoEnable = true;
  };

  nix.enable = true;
}
