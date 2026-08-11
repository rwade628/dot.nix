# Homebrew integration for GUI apps not well-packaged in nixpkgs for aarch64-darwin
# (mostly proprietary/closed-source macOS software). No casks are chosen here -
# that's a follow-up once the host builds and switches successfully.
{ ... }:
{
  homebrew = {
    enable = true;
    casks = [ ];
    brews = [ ];
    taps = [ ];
  };
}
