# User packages (home-manager level)
# OWNERSHIP: These are user-specific applications installed via home-manager.
# This is the only package list available on non-NixOS (darwin) hosts, so
# personal/interactive CLI tools belong here rather than in
# modules/nixos/core/packages.nix, which darwin hosts never import.
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
      claude-code # AI chat agent TUI for Claude

      # Development tools
      uv # Python package manager
      fzf # Fuzzy finder

      # Additional user tools
      git-secret # Git encryption for secrets (user-specific script)

      # Homelab / Kubernetes tooling (formerly mise-managed in the homelab repo)
      age
      cilium-cli
      cloudflared
      cue
      fluxcd # provides `flux`
      gh
      go-task # provides `task`
      helmfile
      jq
      kubeconform
      kubectl
      kubernetes-helm # provides `helm`
      kustomize
      sops
      talhelper
      talosctl
      yq-go # provides `yq`

      # Editors
      micro # Simple terminal editor
      # neovim comes from programs.lazyvim (modules/home/core/neovim)

      # Terminal / file managers
      zellij # Terminal workspace
      yazi # Modern terminal file manager
      superfile # Interactive terminal file manager
      file # MIME type detection (yazi preview dependency)
      # tmux comes from programs.tmux (modules/home/core/tmux)

      # CLI power tools & utilities
      _1password-cli # 1Password CLI
      act # Run GitHub Actions locally
      asciinema # Terminal session recorder
      atuin # Shell history with sync
      bandwhich # Network bandwidth monitor
      bat # Cat clone with syntax highlighting
      # btop comes from programs.btop (modules/home/core/btop.nix)
      devbox # Nix-based dev environments
      dnsutils # DNS tools (dig, nslookup, host)
      duf # Disk usage/df replacement
      # eza comes from modules/home/core/zsh
      fd # Fast find alternative
      git-filter-repo # Git repository rewriting
      git-lfs # Git large file storage
      gnugrep # grep with better defaults
      gnused # sed with better defaults
      gpg-tui # TUI for GPG
      gping # Ping with graph
      hcloud # Hetzner Cloud CLI
      htop # Process viewer
      iperf3 # Network bandwidth tool
      just # Command runner (make alternative)
      lastpass-cli # LastPass CLI
      lazydocker # TUI for docker
      lazygit # TUI for git
      nixfmt # Nix formatter
      ookla-speedtest # Speed test
      packer # Packer CLI
      parallel # Parallel command execution
      procs # Modern ps alternative
      pwgen # Password generator
      rclone # Cloud storage sync
      ripgrep # Fast grep alternative
      rsync # File sync tool
      starship # Cross-shell prompt
      tealdeer # Fast man page viewer
      terraform # Infrastructure as code
      tokei # Code statistics
      tre-command # Tree alternative
      tree # Directory tree viewer
      typst # Modern typesetting
      zoxide # Smart cd replacement

      # Package managers
      cachix # Binary cache client
      bun # JavaScript runtime/package manager
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      trashy # trash cli (not packaged for Darwin)
      trickle # Rate limiter (not packaged for Darwin)
    ]
    ++ lib.optionals host.hasDesktop [
      # GUI Apps
      wireshark # packet inspection
    ]
    ++ lib.optionals (host.hasDesktop && pkgs.stdenv.hostPlatform.isLinux) [
      vlc # media player (not packaged for Darwin)
    ];
}
