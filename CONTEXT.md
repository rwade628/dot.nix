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
