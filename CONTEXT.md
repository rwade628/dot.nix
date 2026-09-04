# Dot.nix Host Configuration

This repo provisions Ryan's machines as a Nix flake. The domain here is "hosts" — how a
machine declares its role, platform, and characteristics, and how that drives which system
and user-level config gets built for it.

## Language

**Host**:
A machine this flake produces a full system configuration for, keyed by hostname in
`lib/hosts.nix` and given a directory under `hosts/<platform>/<hostname>/`.
_Avoid_: machine, node, box.

**Platform**:
The OS a host runs — `nixos` or `darwin` — which determines which builder (`mkHost` vs
`mkDarwinHost`) and which module tree (`modules/nixos/*` vs `modules/darwin/*`) apply to it.
Distinct from CPU architecture (`x86_64` vs `aarch64`), which platform folders do not encode.
_Avoid_: OS (used loosely elsewhere, but Platform is the term with a home in the code).

**hasDesktop**:
Whether a host should receive GUI application packages, GUI fonts, and desktop-oriented
services. For NixOS hosts it defaults from `niri || plasma`; Darwin hosts set it explicitly,
since they have no window-manager flag to derive it from. This is the single gate GUI
packages check.
_Avoid_: isServer (no longer a GUI gate), isDesktop.

**isServer**:
Whether a host's role is a headless, always-on network service (open ports, long-running
daemons like Harmonia). Purely about role — does not imply and is not implied by
`hasDesktop`.
_Avoid_: headless (ambiguous with hasDesktop), isMinimal (a separate, stricter flag that also
turns off home-manager's full user profile).

**Portable package**:
A package that (a) has a working `aarch64-darwin` build in nixpkgs and (b) is useful standalone
from a terminal — it needs no Linux kernel interface (PCI/USB/`/dev`), no systemd unit, and no
desktop session. Portable packages belong in the shared package list, not a platform tree.
_Avoid_: cross-platform tool (imprecise — doesn't rule out the systemd/hardware dependency case).

**Platform-bound package**:
A package that fails the Portable package test — it depends on a Linux kernel interface, a
systemd unit, or hardware access unavailable on Darwin (e.g. `ethtool`, `keyd`, `lm_sensors`).
Stays in `modules/nixos/core/packages.nix`, never the shared list, even though nothing stops it
from being installed there mechanically.
_Avoid_: NixOS-only (true but doesn't name why).

**Shared package list**:
`modules/home/core/packages.nix` — the one `home.packages` list home-manager applies to every
host regardless of platform (NixOS or Darwin) or desktop status. The canonical destination for
any Portable package currently stranded in a platform-specific tree.
_Avoid_: common packages, base packages (used loosely elsewhere; this is the term with a home in
the code).

**Host override**:
`modules/home/hosts/<hostname>/` — config specific to one physical/named host and nothing else:
path shims (`idun/paths.nix`'s `/Users/...` layout), one-off hardware quirks, module imports
unique to that host. Never a place for Portable packages, which belong in the Shared package
list even when only one host currently needs them (gated on `hasDesktop`/platform instead of
pinned to a hostname) — see `docs/adr/0004-portable-packages-live-in-shared-list.md`.
_Avoid_: host config (too vague — nearly everything under `modules/home/hosts` and
`hosts/<platform>/<hostname>` could be called that).
