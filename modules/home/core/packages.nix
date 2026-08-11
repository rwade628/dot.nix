# User packages (home-manager level)
# OWNERSHIP: These are user-specific applications installed via home-manager
# These packages should NOT be duplicated in modules/nixos/core/packages.nix
{
  pkgs,
  lib,
  host,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      # Environment & directory management
      direnv # environment per directory

      # Utilities
      coreutils # standard gnu utils
      dust # disk usage (du replacement)
      lazyjournal # journalctl viewer
      unrar # rar extraction

      # File operations (partial - unzip in system)
      zip # zip compression
      unzip # zip extraction

      opencode # media tools

      # Development tools
      uv # Python package manager
      fzf # Fuzzy finder

      # Additional user tools
      git-secret # Git encryption for secrets (user-specific script)
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      trashy # trash cli (not packaged for Darwin)
    ]
    ++ lib.optionals host.hasDesktop [
      # GUI Apps
      wireshark # packet inspection
    ]
    ++ lib.optionals (host.hasDesktop && pkgs.stdenv.isLinux) [
      vlc # media player (not packaged for Darwin)
    ];
}
