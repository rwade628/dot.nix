# hasDesktop flag decouples GUI package gating from isServer

GUI-app gating (`modules/nixos/core/packages.nix`, `modules/home/core/packages.nix`,
`modules/nixos/core/fonts.nix`) all used `!host.isServer` to decide whether a host got things
like `vlc`, `wireshark`, `wine`, and desktop fonts. This conflated two unrelated concepts: "is
this host's role a headless network server" and "does this host want GUI apps." The
conflation had already caused a real bug — `nix-cache` (an LXC Harmonia cache) was missing
`isServer = true` in `lib/hosts.nix`, so it silently received the full GUI package set. It
also had no way to express "give this host GUI apps" for the new Darwin host, which has no
server role and no `niri`/`plasma` flag to derive a desktop-presence signal from.

We added `host.hasDesktop` to `modules/global/host-spec.nix`. For NixOS hosts it defaults to
`niri || plasma` (self-correcting the nix-cache leak with no manual flag needed, since neither
is set there). Darwin hosts set it explicitly, since macOS's desktop (Aqua) isn't behind a
window-manager flag. Every GUI-app/font gate that previously checked `!host.isServer` now
checks `host.hasDesktop` instead. `isServer` reverts to meaning only server role — it no
longer has any bearing on installed packages.
