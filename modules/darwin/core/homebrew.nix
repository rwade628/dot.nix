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
      # docs/adr/0003-ghostty-via-homebrew-cask.md. Replaces wezterm: with
      # onActivation.cleanup no longer "none", dropping it from this list is
      # what uninstalls it, not merely a bookkeeping change.
      "ghostty"

      # Candidate for removal: nix already provides git-credential-osxkeychain
      # via the git in modules/darwin/core/packages.nix.
      "git-credential-manager"
    ];

    brews = [ ];

    taps = [ ];

    # Enforce the lists above: anything installed that isn't declared here gets
    # uninstalled on activation. The precondition the previous "none" was
    # waiting on is met - no formulae remain in the Cellar.
    #
    # "uninstall", not "zap": the two are identical for enforcing presence, but
    # zap also deletes a cask's application-support data, which would make every
    # future edit to these lists - including a typo - irreversible for user data.
    onActivation.cleanup = "uninstall";
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
