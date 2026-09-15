# Secrets move from git-crypt to sops-nix, keyed per host

`lib/secrets.nix` was a single git-crypt-encrypted file, decrypted wholesale via GPG on any
machine with a registered collaborator key. Several consumers interpolate secret values directly
into module options — `ssh.nix` writes SSH private key contents via `pkgs.writeTextFile`,
`user.nix` sets `hashedPassword` directly, niri/`monitor.nix` bake `HASS_TOKEN` into
`environment.variables`/a generated script — which puts plaintext secret material into
world-readable Nix store paths as a side effect of building the config. This isn't hypothetical:
`loki` is the one host the current nightly job actually builds and caches, `loki` was never
marked `isMinimal`, so it gets the full home-manager profile including `ssh.nix` — meaning the
real SSH private key has likely already been sitting in a store path served by the (LAN-only)
cache.

Moving build compute to GitHub Actions ([ADR-0005](./0005-nix-cache-moves-to-cluster-ci-builds-all-platforms.md))
makes this urgent: CI must be able to build full host closures without ever holding a repo-wide
decryption key, and none of the resulting store paths can carry live secret material once
they're pushed to a more broadly-reachable cache. We're migrating to **sops-nix**: secrets live
as per-host encrypted files (`hosts/<platform>/<hostname>/secrets.yaml` — the Host secrets
file), each decryptable only by that host's Host age key (derived from its existing SSH host
key, so there's no new key to generate or back up), plus one Common secrets file decryptable by
every host's key for values that belong everywhere (e.g. future cluster credentials).
Decryption happens only at activation time, on the real machine — CI never decrypts anything,
because sops files keep key *names* in plaintext and only encrypt values, which is enough for
Nix to evaluate and build the activation script that will later decrypt them. All three current
secret values (password hash, SSH keypair, HA token) are being rotated as part of the cutover,
since the password hash has plausible LAN exposure history and the rest are cheapest to rotate
while every consumer is already being touched.

Considered: a single shared personal age key instead of per-host keys (rejected — collapses all
scoping and becomes one new high-value secret to protect); exporting a git-crypt key to GitHub
Actions instead of migrating (rejected — still hands CI a repo-wide decryption key, and does
nothing about secrets being baked into store paths in the first place).
