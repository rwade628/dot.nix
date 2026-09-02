# GUI fonts for Darwin hosts, symlinked by nix-darwin into
# /Library/Fonts/Nix Fonts.
#
# Mirrors the Nerd Font half of modules/nixos/core/fonts.nix so the shared
# ghostty config (modules/home/core/ghostty.nix) resolves the same family on
# both platforms. Gated on hasDesktop, the same gate the NixOS font module uses.
{
  pkgs,
  lib,
  host,
  ...
}:
{
  fonts.packages =
    with pkgs;
    lib.optionals host.hasDesktop [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
}
