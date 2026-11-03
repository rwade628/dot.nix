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
  # A Work host's machine name belongs to IT; its neutral hostname only
  # selects the flake output.
  networking = lib.mkIf (!host.isWork) {
    hostName = lib.mkDefault host.network.hostName;
    localHostName = lib.mkDefault host.network.hostName;
    computerName = lib.mkDefault host.network.hostName;
  };

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

  nix = {
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Attic, in the homelab cluster (cache "fafnir") - CI is the only
      # writer. idun is a roaming Mac, so the tailnet hostname is the only
      # one that's always reachable - see docs/adr/0005.
      #
      # nix-community also covers aarch64-darwin builds more thoroughly than
      # cache.nixos.org/Hydra does, which is why it's worth having here too.
      #
      # priority=30: below cache.nixos.org (40) and nix-community (both it
      # and fafnir advertise 41). CI pushes each host's whole closure,
      # upstream-signed paths included, so fafnir usually has everything -
      # prefer the tailnet copy over cache.nixos.org's slow local POP.
      #
      # Work hosts skip fafnir: it's Homelab tooling, reachable only over the
      # tailnet, which a Work host never joins - see docs/adr/0007. Without
      # fafnir (which CI fills with the whole closure, catppuccin's derivations
      # included), Work hosts take those from catppuccin's own public cache
      # instead of building them locally.
      substituters =
        lib.optional (!host.isWork) "http://attic.warbler-matrix.ts.net:8080/fafnir?priority=30"
        ++ [ "https://nix-community.cachix.org" ]
        ++ lib.optional host.isWork "https://catppuccin.cachix.org";

      trusted-public-keys =
        lib.optional (!host.isWork) "fafnir:i+z8sCEUusMjfDIEPANiEGrNknaq7ajf8iUwiYwCc8U="
        ++ [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ]
        ++ lib.optional host.isWork "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU=";

      # Fail over quickly when fafnir is unreachable (Mac off the tailnet).
      connect-timeout = 5;
    };
  };
}
