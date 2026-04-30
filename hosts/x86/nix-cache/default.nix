{
  pkgs,
  ...
}:

{
  imports = [
    # (lib.custom.relativeToRoot "modules/nixos/core") # sets up core nixos configuration
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

  networking = {
    enableIPv6 = false;
  };

  environment.systemPackages = with pkgs; [
    git
    nix
    openssh
    jq
    uv
    python3
  ]

  ## System-wide packages ##
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
