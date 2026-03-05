# Shared home-manager desktop configuration
# Loads DE-specific configs based on hostSpec
{
  config,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.optional (host.gnome or false) ./gnome)
    (lib.optional (host.niri or false) ./niri)
    (lib.optional (host.plasma or false) ./plasma)
    ./scripts
    ./ghostty.nix
    ./alacritty.nix
    ./albert.nix
    # ./atuin.nix
  ];

  # Shared desktop configs can go here
}
