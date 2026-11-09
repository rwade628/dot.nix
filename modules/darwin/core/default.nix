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
      # writer. Reached through host.fafnirEndpoint: the tailnet address for
      # personal Macs (idun roams, so it's the only always-reachable one -
      # see docs/adr/0005), the LAN address for a Work host, supplied by its
      # wrapper flake (docs/adr/0008). Null means no fafnir at all.
      #
      # nix-community also covers aarch64-darwin builds more thoroughly than
      # cache.nixos.org/Hydra does, which is why it's worth having here too.
      #
      # priority=30: below cache.nixos.org (40) and nix-community (both it
      # and fafnir advertise 41). CI pushes each host's whole closure,
      # upstream-signed paths included, so fafnir usually has everything -
      # prefer it over cache.nixos.org's slow local POP.
      substituters =
        lib.optional (host.fafnirEndpoint != null) "${host.fafnirEndpoint}/fafnir?priority=30"
        ++ [ "https://nix-community.cachix.org" ];

      trusted-public-keys =
        lib.optional (host.fafnirEndpoint != null) "fafnir:i+z8sCEUusMjfDIEPANiEGrNknaq7ajf8iUwiYwCc8U="
        ++ [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];

      # Fail over quickly when fafnir is unreachable (Mac off the tailnet,
      # or a Work host away from home).
      connect-timeout = 5;
    };
  };

  # A Work host sits behind its employer's DNS, which can't resolve the
  # homelab's internal names - so look up fafnir's host (and only that name)
  # via the home router instead, with a macOS per-name resolver file. Away
  # from home the lookup times out after a second and Nix moves on. See
  # docs/adr/0008.
  assertions = [
    {
      assertion = host.fafnirResolver == null || host.fafnirEndpoint != null;
      message = "fafnirResolver is set but fafnirEndpoint isn't - the resolver only exists to look up fafnirEndpoint's host, so set both or neither.";
    }
  ];

  environment.etc =
    let
      fafnirHost = lib.head (builtins.match "[a-z]+://([^:/]+).*" host.fafnirEndpoint);
    in
    lib.mkIf (host.fafnirResolver != null && host.fafnirEndpoint != null) {
      "resolver/${fafnirHost}".text = ''
        nameserver ${host.fafnirResolver}
        timeout 1
      '';
    };
}
