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
      minijinja # provides `minijinja-cli`
      sops
      stern # multi-pod kubernetes log tailing
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
      sesh # tmux session manager
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
      moreutils # sponge, ts, chronic, vipe, etc.
      nixfmt # Nix formatter
      ookla-speedtest # Speed test
      packer # Packer CLI
      parallel # Parallel command execution
      procs # Modern ps alternative
      pwgen # Password generator
      rclone # Cloud storage sync
      ripgrep # Fast grep alternative
      rsync # File sync tool
      socat # Multipurpose socket relay
      starship # Cross-shell prompt
      tealdeer # Fast man page viewer
      terraform # Infrastructure as code
      tokei # Code statistics
      tre-command # Tree alternative
      tree # Directory tree viewer
      typst # Modern typesetting
      xz # LZMA compression utils
      zoxide # Smart cd replacement

      # Package managers
      cachix # Binary cache client
      bun # JavaScript runtime/package manager

      # Development toolchains (portable: no systemd/hardware dependency, so
      # these live here instead of nixos/core/packages.nix's systemPackages)
      gcc # GNU Compiler Collection
      gnumake # Build automation
      meson # Build system
      nodejs_26 # Node.js runtime
      pkg-config # Manage compile flags
      portaudio # Audio I/O library
      python3
      go # Go toolchain
      krew # kubectl plugin manager

      # Formatters / linters
      nil # Nix language server
      nixpkgs-fmt # Nix formatter (alternate)
      statix # Nix linter

      # More utilities (formerly duplicated per-host in modules/home/hosts)
      ffmpeg # Media transcoding
      nnn # Terminal file manager
      p7zip # 7z archive support
      mtr # Network diagnostic tool (traceroute + ping)
      ldns # Provides `drill`, a dig replacement
      aria2 # Multi-protocol/multi-source download utility
      ipcalc # IPv4/v6 address calculator
      cowsay
      which
      gnutar
      gawk
      zstd
      nix-output-monitor # Provides `nom`
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      # Containers: NixOS hosts get docker from virtualisation.docker /
      # modules/nixos/core/packages.nix, so these are Darwin-only.
      colima # Container runtime VM for macOS
      docker # Docker CLI
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      trashy # trash cli (not packaged for Darwin)
      trickle # Rate limiter (not packaged for Darwin)

      # Diagnostic tools (formerly duplicated per-host, not packaged for Darwin)
      strace # System call tracing
      ltrace # Library call tracing
      sysstat
      iotop
      iftop
    ]
    ++ lib.optionals host.hasDesktop [
      # GUI Apps
      wireshark # packet inspection
    ]
    ++ lib.optionals (host.hasDesktop && pkgs.stdenv.hostPlatform.isLinux) [
      vlc # media player (not packaged for Darwin)

      # GUI/desktop apps with no Darwin build - see
      # docs/adr/0004-portable-packages-live-in-shared-list.md
      spotify
      telegram-desktop
      vesktop
      mullvad-browser
      inspector
      solaar
    ];
}
