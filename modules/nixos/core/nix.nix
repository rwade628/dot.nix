{
  inputs,
  config,
  lib,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    #
    # `self` is deliberately excluded: unlike every other input, it isn't
    # fetched via a pinned github: URL - it's a git+file:// fetch of this
    # working tree, which Nix's git-porcelain fetcher (unlike the
    # GitHub-tarball-API path used for github: inputs) doesn't reproduce
    # identically across machines for identical commits (see
    # https://github.com/NixOS/nix/issues/5313). Registering it here baked
    # that non-reproducible path into /etc/nix/registry.json and $NIX_PATH
    # (via nixPath below), which cascaded into set-environment.drv and
    # friends, forcing a local rebuild of those on every switch even when
    # every actual package substituted fine. All it ever bought was being
    # able to type `self#...`/`<self>` from outside this repo's directory,
    # which `.`/`<nixpkgs>`-style relative usage from inside it already
    # covers.
    registry = lib.mapAttrs (_: value: { flake = value; }) (
      builtins.removeAttrs inputs [ "self" ]
    );

    # This will add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      trusted-users = [
        "@wheel"
        "root"
        "ryan"
      ];
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      warn-dirty = false;

      allow-import-from-derivation = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Binary cache substituters
      substituters = [
        "https://cache.nixos.org"
        # "https://chaotic-nyx.cachix.org"
        # "https://nix-community.cachix.org"
        "https://cache.nixos-cuda.org"
        # Attic, in the homelab cluster (cache "fafnir") - CI is the only
        # writer. Reachable over Tailscale (see docs/adr/0005), and the
        # hostname is the tailnet one even for LAN-only hosts like loki -
        # see the homelab repo's attic server.toml for why.
        "http://attic.warbler-matrix.ts.net:8080/fafnir"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        # "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "fafnir:i+z8sCEUusMjfDIEPANiEGrNknaq7ajf8iUwiYwCc8U="
      ];
    };
  };
}
