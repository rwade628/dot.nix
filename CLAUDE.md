# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Ryan's NixOS dotfiles configuration, managed as a Nix flake using `flake-parts`. It provisions three hosts: **nixos** (KDE Plasma desktop), **loki** (headless WSL server), and **nix-cache** (LXC container running a Harmonia binary cache). The config uses home-manager for user environments, catppuccin for theming (macchiato/lavender), and supports Niri and Plasma desktops.

## Key Commands

```bash
# Enter development shell (provides nix, nixos-rebuild, home-manager, nh, etc.)
nix develop

# Rebuild a specific host
nixos-rebuild switch --flake .#nixosConfigurations.<hostname>
# Examples:
nixos-rebuild switch --flake .#nixosConfigurations.nixos
nixos-rebuild switch --flake .#nixosConfigurations.loki
nixos-rebuild switch --flake .#nixosConfigurations.nix-cache

# Preferred local rebuild (uses nh, shorter output, auto-generation-diffing)
nh os switch . --hostname <hostname>

# Build a host without switching
nixos-rebuild build --flake .#nixosConfigurations.<hostname>

# Rebuild pinned to the nixpkgs revision the cache server last built (maximizes cache hits)
scripts/nix/upgrade-from-cache.sh

# Home-manager switch (runs via nixos-rebuild modules)
home-manager switch --flake .#homeConfigurations.<hostname>.<user>

# Validate the flake (evaluates all outputs, including host assertions)
nix flake check

# Update flake inputs
nix flake update

# Check rebuild status
yay rebuild

# Clean old generations (configured via nh)
nh clean all --keep 10 --keep-since 10d
```

Hosts are defined in `hosts/x86/<hostname>/default.nix` and imported by `modules/flake/nixos.nix` via `mkHost`. The `lib.custom.getHostsData pkgs` function evaluates all host specs for inspection.

## Architecture

```
flake.nix                          # Root flake, declares inputs + delegates to flake-parts
├── modules/flake/                 # flake-parts pieces
│   ├── nixos.nix                  # Generates nixosConfigurations per host
│   ├── overlays.nix               # Package overlays (additions, modifications, stable/unstable namespaces)
│   ├── packages.nix               # Exposes pkgs/* as flake packages
│   └── devshell.nix               # perSystem dev shell with all dev tools
├── modules/global/                # Shared spec modules (type definitions)
│   ├── host-spec.nix              # HostSpec option types (network, mounts, DE, user, flags)
│   └── secret-spec.nix            # SecretsSpec option types (users, SSH, GPG, SMTP, services)
├── modules/nixos/                 # NixOS modules
│   ├── core/                      # Shared across all hosts: nix, ssh, user, fonts, packages, services
│   ├── desktop/                   # niri/ and plasma/ system-level DE config
│   ├── hardware/                  # audio.nix
│   └── services/                  # ai, ddcutil, plymouth, gaming (steam/gamescope/lutris/sunshine)
├── modules/home/                  # Home-manager modules
│   ├── core/                      # Shared user config: neovim, zsh, bash, git, ssh, direnv, tmux, etc.
│   ├── desktop/                   # niri/ and plasma/ user-level DE config (binds, windows, apps)
│   ├── gaming/                    # mangohud, lsfgvk
│   ├── hosts/                     # Per-host user overrides (loki/, nixos/, nix-cache/)
│   ├── users/ryan/                # User-level config + theme
│   └── utilities/                 # xdg, mullvad
├── hosts/x86/<hostname>/          # Per-host configuration drop-ins
│   ├── default.nix                # Imports core modules + host-specific services
│   └── *.nix                      # Host-specific overrides (networking, mounts, nvidia, etc.)
├── lib/                           # Custom library (scanPaths, relativeToRoot, getHostConfig, mkAppriseUrl)
├── pkgs/                          # Custom packages (wine-app-wrapper.nix)
└── docs/agents/                   # Agent instructions: issue-tracker, triage-labels, domain
```

### Spec/Implementation Pattern

Host and secret data use a two-file pattern with `lib.evalModules`:

- **Spec** (`modules/global/host-spec.nix`, `modules/global/secret-spec.nix`): defines option types and validation assertions
- **Implementation** (`lib/hosts.nix`, `lib/secrets.nix`): provides concrete values

This enables type-safe config access via `host.*` and `secrets.*` in specialArgs. Validation runs at flake evaluation time (e.g., VPN without WireGuard, mutually exclusive DEs, minimal hosts without desktop).

### Module Loading

`lib.custom.scanPaths` recursively scans directories for `.nix` files (excluding `default.nix`) and returns paths for import. Each host's `default.nix` uses this to auto-import its drop-in files. The core modules are always explicitly imported: `(lib.custom.relativeToRoot "modules/nixos/core")`.

### Secrets

`lib/secrets.nix` contains encrypted inline secrets (SSH keys, passwords, tokens). The file is marked for git-crypt encryption. Secrets flow into NixOS via `secrets.users.<name>` and `secrets.service` specialArgs.

### Host Characteristics

Each host declares flags in `lib/hosts.nix`:

- `isServer` — no home-manager, no desktop
- `isMinimal` — no home-manager, no desktop (same as isServer currently)
- `isExternal` — not on local network
- `niri` / `plasma` — mutually exclusive desktop environments

Assertions prevent invalid combinations (both DEs, minimal+desktop, VPN without WireGuard).

## Important Conventions

- **stateVersion**: `system.stateVersion` is `25.11` on all hosts; home-manager's `home.stateVersion` defaults to `25.05` (`modules/home/core/default.nix`) except for `root`, which is pinned to `25.11` (`modules/nixos/core/user.nix`)
- **unfree**: enabled globally (`nixpkgs.config.allowUnfree = true`)
- **Wayland-first**: all DE configs target Wayland (Niri native, Plasma via SDDM Wayland)
- **Catppuccin**: macchiato flavor with lavender accent, auto-enabled everywhere
- **Binary caches**: cache.nixos.org, chaotic-nyx, nix-community, nixos-cuda, and local harmonia at `http://10.0.10.14:5000`
- **IPv6**: disabled on all hosts
- **SSH**: key-based auth only, root login disabled, mosh enabled
- **Timezone**: America/New_York
- **Locale**: en_US.UTF-8

## Adding a New Host

1. Add entry to `lib/hosts.nix` under `hostSpec` with network, user, and flags
2. Create `hosts/x86/<hostname>/default.nix` importing core modules and host-specific config
3. Optionally add host-specific drop-in files (mounted auto-scanned by `scanPaths`)
4. If user config needed, add `modules/home/hosts/<hostname>/`

## Adding a New NixOS Module

Place in `modules/nixos/` under the appropriate subdirectory (core, desktop, hardware, services). The module should be a standalone `.nix` file accepting standard NixOS module arguments (`config`, `lib`, `pkgs`, `host`, `inputs`, `secrets`, ...). It will be auto-scanned if placed in a subdirectory, or explicitly imported in a host's `default.nix`.

## Adding a New Home-Manager Module

Place in `modules/home/` under the appropriate subdirectory. Core modules are shared across all hosts; host-specific overrides go under `modules/home/hosts/<hostname>/`. User-level config lives under `modules/home/users/ryan/`.

## Agent skills

### Issue tracker

Issues and PRDs live as GitHub issues, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` + `docs/adr/`. See `docs/agents/domain.md`.

## Gotchas

- **`lib.custom` availability**: propagated into home-manager modules by extending `lib` itself in `specialArgs` (`modules/flake/nixos.nix`), not via `extraSpecialArgs`. Reference it as `lib.custom.*`, not as a standalone arg.
- **Hardcoded flake path**: `programs.nh.flake` in `modules/nixos/core/default.nix:69` is hardcoded to `/home/ryan/git/dot.nix/`. This breaks `nh` on a clone at a different path.
- **`FLAKE` env var**: set via `lib.mkDefault "/home/${host.user.name}/git/dot.nix"` in `modules/home/core/default.nix`; override per-host if the repo is checked out elsewhere.
- **`scanPaths` skips `default.nix`**: any `default.nix` in an auto-scanned directory must be imported explicitly elsewhere — it is never picked up by the scan itself.
- **`neovim.nix` is a redirect**: `modules/home/core/neovim.nix` just imports `./neovim/`; the real config lives in that subdirectory.
- **Wine package**: use `wineWow64Packages.full` (or `.waylandFull`/`.stable`), not `wineWowPackages.full`.
- **Secrets encryption**: `lib/secrets.nix` is transparently encrypted via `git-crypt` per `.gitattributes` — `git-crypt status` should show it as `encrypted`. Never bypass this (e.g. `git-crypt unlock` output, `git show` on old unencrypted history) when a public remote is involved.
- **NixOS/Home Manager lookups**: prefer the `nixos` MCP server's `nix`/`nix_versions` tools over guessing option names or package attributes — nixpkgs moves faster than training data.
