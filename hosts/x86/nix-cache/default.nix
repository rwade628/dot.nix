{ ... }:

{
  imports = [
    # LXC base configuration (Tier 1)
    ./lxc-container.nix

    # Optional modules (Tier 2)
    # Note: nix-cache is a headless build server, no desktop/audio
    ./virtualization.nix

    # Host-specific modules (Tier 3)
    ./networking.nix
    ./nix-build.nix
    ./harmonia.nix
    ./system-packages.nix
    ./auto-build.nix
  ];
}
