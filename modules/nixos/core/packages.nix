# System packages shared by all hosts
#
# OWNERSHIP: These are system-level packages installed via NixOS
# All packages listed here should NOT be duplicated in home-manager
# User-specific apps should go in modules/home/core/packages.nix
{ pkgs, ... }:

let
  # --- Base System Tools ---
  # Essential utilities for system operation and basic commands
  baseSystemTools = with pkgs; [
    # Core utilities (already in base system, but explicit for clarity)
    coreutils # Basic GNU utilities (ls, cp, rm, etc.)
    curl # URL transfer tool
    ethtool # Network device configuration
    git # Version control
    git-crypt # Git file encryption
    gnupg # OpenPGP encryption
    gpg-tui # TUI for GPG
    openssh # SSH client/server
    pciutils # PCI device information
    sshfs # SSH filesystem client
    wget # Web downloader
  ];

  # --- Package Managers ---
  # Tools for managing software packages
  packageManagers = with pkgs; [
    cachix # Binary cache client
    bun # JavaScript runtime/package manager
    uv # Pythong package manager
  ];

  # --- Editors ---
  # Text editors for system-wide use
  editors = with pkgs; [
    micro # Simple terminal editor
  ];

  # --- File Managers ---
  # File management utilities
  fileManagers = with pkgs; [
    yazi # Modern terminal file manager
    superfile # Interactive terminal file manager
  ];

  # --- CLI Power Tools & Utilities ---
  # Enhanced command-line tools for productivity
  cliPowerTools = with pkgs; [
    _1password-cli # 1Password CLI
    act # Run GitHub Actions locally
    asciinema # Terminal session recorder
    atuin # Shell history with sync
    bandwhich # Network bandwidth monitor
    bat # Cat clone with syntax highlighting
    btop # System monitor
    cups # Printing system (lp command)
    docker # Container platform
    devbox # Nix-based dev environments
    dnsutils # DNS tools (dig, nslookup, host)
    duf # Disk usage/df replacement
    eza # ls replacement
    fd # Fast find alternative
    fzf # Fuzzy finder
    gh # GitHub CLI
    git-filter-repo # Git repository rewriting
    git-lfs # Git large file storage
    git-secret # Git encryption for secrets
    gnugrep # grep with better defaults
    gnused # sed with better defaults
    gping # Ping with graph
    hcloud # Hetzner Cloud CLI
    htop # Process viewer
    iperf3 # Network bandwidth tool
    jq # JSON processor
    just # Command runner (make alternative)
    keyd # Keyboard daemon
    lazydocker # TUI for docker
    lazygit # TUI for git
    lm_sensors # Hardware sensors
    lsof # List open files
    mosh # Mobile shell
    neovim # Modern vim
    nixfmt # Nix formatter
    nmap # Network scanner
    ookla-speedtest # Speed test
    opencode # AI chat agent TUI
    packer # Packer CLI
    parallel # Parallel command execution
    postgresql # PostgreSQL database
    procs # Modern ps alternative
    psmisc # Utilities (killall)
    pwgen # Password generator
    rclone # Cloud storage sync
    ripgrep # Fast grep alternative
    rsync # File sync tool
    starship # Cross-shell prompt
    tealdeer # Fast man page viewer
    terraform # Infrastructure as code
    tmux # Terminal multiplexer
    tokei # Code statistics
    trashy # trash CLI
    tre-command # Tree alternative
    tree # Directory tree viewer
    typst # Modern typesetting
    unrar # RAR extraction
    unzip # ZIP extraction
    usbutils # USB device tools
    wakeonlan # Wake-on-LAN utility
    yq-go # YAML processor
    zellij # Terminal workspace
    zoxide # Smart cd replacement
  ];

  # --- Gaming ---
  # Gaming-related system packages
  gaming = with pkgs; [
    wineWow64Packages.full # Wine implementation
    winetricks # Wine helper script
  ];

  # --- AI Tools ---
  # Artificial intelligence tools
  ai = with pkgs; [
    llama-cpp # LLM inference
  ];

  # --- Yazi Preview Dependencies ---
  # Required for yazi file manager previews
  yaziPreviewDeps = with pkgs; [
    file # MIME type detection
  ];

  # --- Development Toolchains ---
  # Programming language toolchains and build tools
  developmentToolchains = with pkgs; [
    gcc # GNU Compiler Collection
    gnumake # Build automation
    meson # Build system
    nodejs_20 # Node.js runtime
    pkg-config # Manage compile flags
    portaudio # Audio I/O library
    (python3.withPackages (ps: [ ps.pipx ])) # Python with pipx
  ];
in
{
  environment.systemPackages =
    baseSystemTools
    ++ packageManagers
    ++ editors
    ++ fileManagers
    ++ cliPowerTools
    ++ gaming
    ++ ai
    ++ yaziPreviewDeps
    ++ developmentToolchains;
}
