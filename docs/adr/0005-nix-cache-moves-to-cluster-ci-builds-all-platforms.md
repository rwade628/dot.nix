# Nix cache moves into the homelab cluster; GitHub Actions builds every platform

`nix-cache` was an Incus LXC container on TrueNAS running Harmonia (pull-only — it just serves
its own local `/nix/store`), fed by a nightly systemd timer that built only
`nixosConfigurations.loki` and never touched Darwin. That structurally couldn't cache anything
for `idun` (aarch64-darwin), and adding a new custom package only got cached if it happened to
be part of `loki`'s closure — otherwise it required a manual local build.

We're replacing this with **Attic** (push-based, designed for multiple builders pushing into one
cache — unlike Harmonia, which only knows how to serve its own disk) running in the homelab
cluster, and moving build compute to **GitHub Actions**. `dot.nix` is a public repo, so GitHub's
macOS runners are free — the only realistic way to produce Darwin outputs without owning
dedicated Apple hardware. CI discovers and builds every flake output generically (`packages.*`
for all four systems, plus every `nixosConfigurations`/`darwinConfigurations` except `nixos`,
which isn't currently deployed anywhere) rather than the hand-maintained package list
`update_overrides.py` used to track — so a new custom package (e.g. `talosctl`) is cached
automatically on the next CI run, no script edit required. CI is the cache's only writer; local
machines are read-only substituters. Triggers: on push to `main` (fast feedback), and a nightly
`nix flake update` run that only commits the updated lockfile if the resulting build is green
(preserves the old auto-build's "never advance to an unbuildable revision" guarantee).

Considered: keeping Harmonia and just relocating the VM (rejected — doesn't fix the "must
physically build on the serving machine" limitation that caused the Darwin gap in the first
place); Cachix hosted (rejected — not self-hosted, and the goal was explicitly to run this in
the homelab cluster).

The `nix-cache` host (`hosts/x86/nix-cache/`, its `lib/hosts.nix` entry,
`modules/home/hosts/nix-cache/`) is removed from this repo once the new Attic deployment is
verified working — see the `homelab` repo's `docs/adr/0015-nix-cache-attic-in-cluster.md` for
the cluster-side deployment.
