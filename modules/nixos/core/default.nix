# IMPORTANT: This is used by NixOS and nix-darwin so options must exist in both!
{
  inputs,
  outputs,
  config,
  host,
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = lib.flatten [
    inputs.home-manager.nixosModules.home-manager
    (lib.custom.scanPaths ./.)

    (map lib.custom.relativeToRoot [
      "modules/global"
    ])
    inputs.catppuccin.nixosModules.catppuccin

    # Desktop environment (if enabled)
    (lib.optional (host.niri or false) (lib.custom.relativeToRoot "modules/nixos/desktop/niri"))
    (lib.optional (host.plasma or false) (lib.custom.relativeToRoot "modules/nixos/desktop/plasma"))
  ];

  environment.localBinInPath = true;

  services.devmon.enable = true;

  # Enable print to PDF.
  services.printing.enable = true;

  # Enable CUPS printing
  services.printing.drivers = [ pkgs.cups-dymo ];

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
    config = {
      allowUnfree = true;
      # allowUnfreePredicate = _: true;
      # permittedInsecurePackages = [
      #   "mbedtls-2.28.10"
      # ];
    };
  };

  ## Localization ##
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = lib.mkDefault "America/New_York";
  networking.timeServers = [ "pool.ntp.org" ];
  environment.sessionVariables.TZ = config.time.timeZone;

  ## Nix Helper ##
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 10d --keep 10";
    flake = "/home/ryan/git/dot.nix/";
  };

  ## SUDO and Terminal ##
  environment.enableAllTerminfo = true;
  hardware.enableAllFirmware = true;

  security.sudo = {
    extraConfig = ''
      Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
      Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
      Defaults timestamp_timeout=120 # only ask for password every 2h
      # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
      Defaults env_keep+=SSH_AUTH_SOCK
    '';
  };

  ## Primary shell enablement ##
  programs.zsh.enable = true;
  environment.shells = with pkgs; [
    zsh
    bash
  ];

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  catppuccin = {
    enable = true;
    autoEnable = true;
  };

  ## NIX NIX NIX ##
  documentation.nixos.enable = lib.mkForce false;
}
