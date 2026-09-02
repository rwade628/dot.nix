# Ghostty comes from a Homebrew cask, not nixpkgs

Ghostty is the terminal emulator on every desktop host, including the Darwin host `idun`, and on
`idun` it is installed as a `homebrew.casks` entry while its configuration stays in home-manager
(`programs.ghostty` with `package = null`, which the home-manager module supports explicitly for
platforms where the package is unavailable).

The reason is narrow and worth stating precisely, because ADR 0001's homebrew paragraph — "GUI
apps that aren't well-packaged in nixpkgs for `aarch64-darwin`" — invites the wrong inference
here. Ghostty is not merely awkward to package on Darwin; nixpkgs has no Darwin build of it at
all (`meta.platforms` lists only Linux systems), because upstream's macOS application is a
Swift/Xcode build that nixpkgs cannot reproduce. Nothing about `idun` or about nix-darwin is the
obstacle.

Nix-native alternatives did exist and were rejected. Checked against the pinned nixpkgs on
`aarch64-darwin`, `kitty`, `alacritty`, `wezterm` and `rio` all build; only `ghostty` and `foot`
do not. Choosing any of them would have made `idun`'s terminal fully declarative, but at the
price of either switching terminals on the NixOS hosts too, or running a different terminal on
the Mac than on the desktop — two configurations and two sets of muscle memory, diverging
indefinitely. We valued one shared terminal configuration across every desktop host above
declarative purity for one program on one host. The cost we accepted: `darwin-rebuild switch` no
longer fully determines `idun`'s terminal, since the cask's version floats outside `flake.lock`
and `nix flake check` cannot see it. Configuration is unaffected — home-manager still owns it,
and Ghostty reads the XDG config path on macOS as well as Linux, so the same module serves both
platforms.

This is not a general policy that GUI software must come from Homebrew on Darwin. Nix-installed
GUI applications work under nix-darwin: it rsyncs `.app` bundles into `/Applications/Nix Apps`
as real directories (not symlinks) specifically so Spotlight and Launchpad index them. Any GUI
package that builds for `aarch64-darwin` should still come from nixpkgs; the cask list is for
software that nixpkgs cannot provide, of which Ghostty is currently an instance. If nixpkgs ever
gains a Darwin build of Ghostty, this decision should be revisited and the cask dropped.
