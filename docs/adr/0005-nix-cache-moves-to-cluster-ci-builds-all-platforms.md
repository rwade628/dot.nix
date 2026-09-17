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

## Follow-up: `nix-cache` removed, `upgrade-from-cache.sh` retired

With CI proven out, the `nix-cache` host tree, its `lib/hosts.nix` entry, and
`modules/home/hosts/nix-cache/` were deleted, and its sops age key was dropped as a recipient of
`secrets/common.yaml` (`sops updatekeys`) since the box no longer exists to hold the matching
private key.

`scripts/nix/upgrade-from-cache.sh` SSHed into `nix-cache` to read a per-host
last-known-good-revision file that the old auto-build timer wrote, then pinned `nixpkgs` to it
before rebuilding — necessary because that timer only ran occasionally and only against `loki`,
so a host's `flake.lock` could otherwise drift well past what was actually cached. CI removes
that gap: every push to `main` builds and pushes to Attic, and the nightly `nix flake update` job
only advances `flake.lock` on `main` when the resulting build is green. A plain `git pull` (or
just staying on `main`) followed by `nh os switch .` now rebuilds against a `flake.lock` that CI
has already built and cached, on every host `packages`/`nixosConfigurations`/
`darwinConfigurations` covers — so the script's SSH-and-override dance no longer buys a better
cache hit rate than not having it, and it was deleted rather than repointed.
