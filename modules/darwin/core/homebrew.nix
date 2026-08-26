# Homebrew integration for GUI apps not well-packaged in nixpkgs for aarch64-darwin
# (mostly proprietary/closed-source macOS software).
#
# OWNERSHIP: Only GUI/cask software belongs here. CLI tools go in
# modules/home/core/packages.nix so they are shared with the Linux hosts.
{ ... }:
{
  homebrew = {
    enable = true;

    casks = [
      # Terminal emulator. nixpkgs' wezterm is unreliable on aarch64-darwin,
      # so it stays a cask. NOTE: ~/.config/wezterm is currently a dangling
      # symlink into the retired ~/dotfiles tree.
      "wezterm"

      # Candidate for removal: nix already provides git-credential-osxkeychain
      # via the git in modules/darwin/core/packages.nix.
      "git-credential-manager"
    ];

    brews = [ ];

    # Not declared: sikarugir. It lives in the third-party tap
    # sikarugir-app/sikarugir, which brew refuses to load without an explicit
    # `brew trust`, so `brew bundle` fails on it. The already-installed copy is
    # left alone by onActivation.cleanup = "none".
    taps = [ ];

    # Leave pre-existing brew state alone for now. Once the formulae migrated
    # to nix have been uninstalled by hand, flip this to "zap" so nix-darwin
    # enforces the lists above.
    onActivation.cleanup = "none";
  };
}
