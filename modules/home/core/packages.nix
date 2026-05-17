# User packages (home-manager level)
# OWNERSHIP: These are user-specific applications installed via home-manager
# These packages should NOT be duplicated in modules/nixos/core/packages.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Environment & directory management
    direnv # environment per directory

    # Utilities
    coreutils # standard gnu utils
    dust # disk usage (du replacement)
    lazyjournal # journalctl viewer
    trashy # trash cli
    unrar # rar extraction
    wireshark # packet inspection

    # File operations (partial - unzip in system)
    zip # zip compression
    unzip # zip extraction

    # Media
    vlc # media player
    opencode # media tools

    # Development tools
    uv # Python package manager
    fzf # Fuzzy finder

    # Additional user tools
    git-secret # Git encryption for secrets (user-specific script)
  ];
}
