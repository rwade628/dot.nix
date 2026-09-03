# Ghostty - the daily-driver terminal on every desktop host.
#
# Lives in core rather than under a desktop-environment tree so `idun` (darwin,
# which sets no DE flag) gets the same config as the Plasma hosts. `hasDesktop`
# is the single gate GUI packages check.
{
  host,
  lib,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = host.hasDesktop;

    # nixpkgs has no darwin build of ghostty (`meta.platforms` is Linux-only),
    # so `idun` installs it as a homebrew cask instead - see
    # docs/adr/0003-ghostty-via-homebrew-cask.md. A null package still writes
    # the config to the XDG path, which ghostty reads on macOS too, and skips
    # the `+validate-config` change hook that would invoke a missing binary.
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;

    # No home.sessionVariables.TERM here, unlike the plasma module this
    # replaces. Ghostty exports TERM=xterm-ghostty itself, and the old
    # TERM="ghostty" named a terminfo entry that does not exist - set through
    # sessionVariables it also leaked into every other shell, including ssh
    # sessions to hosts that have no ghostty terminfo at all.

    # Sources a path under $GHOSTTY_RESOURCES_DIR - a variable ghostty exports
    # at runtime - behind a readability guard, so it never touches the package
    # and works with a null one.
    enableZshIntegration = true;

    settings = {
      # `theme` is deliberately absent: the catppuccin module owns it and emits
      # a `light:`/`dark:` pair that follows the system appearance. This config
      # format treats lists as duplicate keys, so a second definition here would
      # be emitted alongside catppuccin's rather than replacing it.

      # Named explicitly rather than via the `monospace` fontconfig alias, which
      # has no meaning on macOS and would fall back to a system font without
      # Nerd Font glyphs.
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = lib.mkDefault "11";

      background-opacity = lib.mkDefault "0.85";
      background-opacity-cells = true;
      keybind = ''shift+enter=text:\x1b\r'';
      window-height = lib.mkDefault 45;
      window-width = lib.mkDefault 145;
      window-inherit-working-directory = true;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Make Option send Escape so word-motion bindings reach the shell.
      macos-option-as-alt = true;
    };
  };
}
