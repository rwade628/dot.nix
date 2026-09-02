# Homebrew integration for GUI apps not well-packaged in nixpkgs for aarch64-darwin
# (mostly proprietary/closed-source macOS software).
#
# OWNERSHIP: Only GUI/cask software belongs here. CLI tools go in
# modules/home/core/packages.nix so they are shared with the Linux hosts.
# The PATH ordering below enforces that rule at runtime.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  prefix = config.homebrew.prefix;
  # `brew --repository`: the same directory as the prefix on Apple Silicon,
  # a subdirectory of it on Intel.
  repository = if pkgs.stdenv.hostPlatform.isAarch64 then prefix else "${prefix}/Homebrew";
in
{
  homebrew = {
    enable = true;

    casks = [
      # Terminal emulator, configured by modules/home/core/ghostty.nix. nixpkgs
      # has no darwin build at all, so the cask is the only option - see
      # docs/adr/0003-ghostty-via-homebrew-cask.md. Replaces wezterm, which is
      # no longer declared here (a no-op against the installed app while
      # onActivation.cleanup is "none", so it is reversible).
      "ghostty"

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

  # Homebrew is installed but puts nothing on PATH by itself, so `brew` cannot
  # be run from a shell. Order 1100 places these after every nix profile
  # (order 1000) and before /usr/bin (order 1200), so a brew-installed CLI can
  # never shadow the nix one. home.sessionPath is the wrong mechanism here:
  # home-manager prepends it, which would invert this ordering.
  environment.systemPath = lib.mkOrder 1100 [
    "${prefix}/bin"
    "${prefix}/sbin"
  ];

  environment.variables = {
    HOMEBREW_PREFIX = prefix;
    HOMEBREW_CELLAR = "${prefix}/Cellar";
    HOMEBREW_REPOSITORY = repository;
  };
}
