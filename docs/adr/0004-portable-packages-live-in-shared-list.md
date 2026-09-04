# Portable packages live in the shared list, gated by capability not hostname

Reviewing `modules/nixos/**` for packages that could run on Darwin too turned up two
patterns of misplacement: (1) genuinely portable CLI tools (`gcc`, `nodejs`, `python3`,
`meson`, `pkg-config`, `portaudio`) sitting in `modules/nixos/core/packages.nix`'s
`environment.systemPackages`, invisible to `idun`; and (2) desktop/social apps (`spotify`,
`telegram-desktop`, `vesktop`, `mullvad-browser`, `inspector`, `solaar`) hardcoded into
`modules/home/hosts/nixos/config/default.nix` — the `nixos` host's own override file — even
though nothing about them is specific to that *hostname*, only to it being the one desktop
host in the fleet at the time they were added.

We chose to move both categories into the shared package list (`modules/home/core/packages.nix`),
gating the desktop/social apps on `host.hasDesktop` (and `isLinux` where nixpkgs has no Darwin
build) rather than leaving them pinned to `modules/home/hosts/nixos/`. `idun` doesn't need most
of them today, but the alternative — re-copy-pasting a "GUI apps" block into every future desktop
host's override file, as had already started happening between `nixos` and `loki`'s host files
for unrelated CLI tools — is exactly the duplication this pass exists to undo. `hasDesktop` (ADR
0002) already exists as the correct capability gate for "does this host want GUI apps"; using it
here instead of a hostname check means a second desktop host — Linux or Darwin — gets the same
set with no file to remember to copy.

Host override files (`modules/home/hosts/<hostname>/`) are reserved for things that are actually
about *that machine* — path shims, one-off hardware, unique module imports — not a place to
route packages just because only one host happens to want them today.
