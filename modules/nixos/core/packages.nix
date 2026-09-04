# System packages shared by all hosts
#
# OWNERSHIP: These are system-level packages installed via NixOS - things
# needed outside a user session (system services, hardware/network
# diagnostics, dev toolchains) or required by other system/root scripts.
# Personal interactive CLI tools belong in modules/home/core/packages.nix
# instead, since that's what's available on non-NixOS (darwin) hosts too.
{
  pkgs,
  lib,
  host,
  ...
}:

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
    openssh # SSH client/server
    pciutils # PCI device information
    sshfs # SSH filesystem client
    wget # Web downloader
    tcpdump
    wl-clipboard
  ];

  # --- System / Diagnostic Tools ---
  # Tools that need to run as root, are tied to a system service, or are
  # otherwise not meaningful as a plain per-user package
  systemTools = with pkgs; [
    cups # Printing system (lp command)
    docker # Container platform
    keyd # Keyboard daemon
    lm_sensors # Hardware sensors
    lsof # List open files
    nmap # Network scanner
    postgresql # PostgreSQL database
    psmisc # Utilities (killall)
    usbutils # USB device tools
    wakeonlan # Wake-on-LAN utility
  ];

  # --- Gaming ---
  # Gaming-related system packages
  gaming =
    with pkgs;
    lib.optionals host.hasDesktop [
      wineWow64Packages.full # Wine implementation
      winetricks # Wine helper script
    ];

  # --- AI Tools ---
  # Artificial intelligence tools
  ai = with pkgs; [
    # llama-cpp # LLM inference
  ];

in
{
  environment.systemPackages = baseSystemTools ++ systemTools ++ gaming ++ ai;
}
