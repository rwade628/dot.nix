# Work hosts: nix-darwin, private values via a wrapper flake, no homelab reach

`brokkr` is an employer-owned Mac, added only to get the same shell, tmux, Neovim and Ghostty
setup as the personal machines. It is a normal nix-darwin host (`hosts/darwin/brokkr`, built by
the same `mkDarwinSystem` as `idun`) flagged `isWork = true`, and that flag withholds everything
that would extend trust from Ryan's personal infrastructure onto a machine someone else controls:
no recipient entry in `.sops.yaml` (so nothing from the Common secrets file), no personal SSH
keys or `sshAuthorizedKeys`, no `sshd`, no Attic substituter, no homelab env vars or
homelab-only CLIs (Homelab tooling, in `CONTEXT.md`), no passwordless sudo, no setting of the
machine name, and Homebrew's `onActivation.cleanup` left at `"none"` so nothing installed outside
this repo is ever removed. Git authenticates with Git Credential Manager over HTTPS (the employer
uses GitHub EMU accounts) rather than a key this repo distributes.

This repo is public, so the host's identifying details — the macOS account name and the work git
name/email — cannot live in `lib/hosts.nix`. They are supplied instead by a **Work wrapper flake**
that exists only on the machine: a ~10-line flake taking this repo as an input and calling
`dotnix.lib.mkDarwinSystem { hostName = "brokkr"; hostSpec = { ... }; }`, whose `hostSpec` is
merged over the public entry. The repo's own `darwinConfigurations.brokkr` builds with
placeholders, which is what CI builds. The work git identity becomes a plain value
(`user.gitIdentity`) rather than a sops secret: it does land in the Nix store, but only that
machine's store, which belongs to the same employer the identity does. Setup and recovery steps
are in [`docs/work-host-setup.md`](../work-host-setup.md).

The differences are expressed as `isWork` checks inside the existing modules rather than a
parallel `modules/darwin/work` tree. [ADR-0001](./0001-darwin-platform-support.md) chose sibling
trees for NixOS vs Darwin because the two share almost nothing; a Work host differs from `idun` in
a handful of booleans, and a second tree would duplicate the ~90% that is the whole point of
adding the machine.

## Considered options

- **Standalone home-manager** (`homeConfigurations`, no nix-darwin). Initially preferred because
  everything wanted is user-level and it would never touch MDM-managed system state. Rejected once
  it was confirmed that colleagues already run nix-darwin on their work Macs: standalone
  home-manager has no Homebrew module (so no declarative Ghostty cask), cannot put a Nix zsh in
  `/etc/shells`, and would have needed a third builder alongside `mkHost`/`mkDarwinSystem`. If
  nix-darwin ever stops being allowed, this is the fallback, and the wrapper-flake pattern carries
  over unchanged.
- **Reading the username at eval time** (`builtins.getEnv "USER"`). Rejected: requires `--impure`
  on every switch, and makes the result depend on whoever runs it.
- **Keeping the wrapper flake in the private `workbench` repo.** Rejected: it would put work
  details on GitHub under a personal account; the wrapper is small enough to recreate from the
  runbook.
- **Joining the work Mac to the tailnet for Attic.** Rejected: it opens a path between an
  employer device and the homelab for a small win — cache.nixos.org already serves stock
  `aarch64-darwin` packages, so Attic would only save local builds of this repo's overlay
  modifications. A read-only public Attic endpoint (a homelab-repo decision) would be the better
  fix if those builds ever become painful.

## Consequences

- dot.nix is edited and pushed from personal machines only; the Work host only pulls it (the repo
  is public, so no auth is needed). An EMU account cannot push to personal repos anyway.
- Anything added to the Common secrets file, the SSH config, or the homelab tooling in
  `modules/home/core/packages.nix` stays off Work hosts by default; something new that *should*
  reach them has to be placed outside those gates deliberately.
