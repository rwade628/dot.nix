# dot.nix — Agent Instructions

## Repo Type

Nix flake dotfiles (flake-parts + home-manager + plasma-manager). Dual config trees: NixOS system + home-manager user.

## Architecture

```
flake.nix                          # Entry: flake-parts, imports 4 modules
├── modules/flake/overlays.nix     # Package overlays (additions, modifications, stable/unstable)
├── modules/flake/nixos.nix        # NixOS host builder (mkHost, reads hosts/<arch>/)
├── modules/flake/packages.nix     # perSystem packages from pkgs/
├── modules/flake/devshell.nix     # Dev shell (nh, nixos-rebuild, home-manager, etc.)
│
├── modules/global/*-spec.nix      # Data spec (type definitions for evalModules)
├── lib/hosts.nix                  # Host data impl (non-sensitive host config)
├── lib/default.nix                # Custom lib (relativeToRoot, scanPaths, getHostConfig)
│
├── hosts/<arch>/<host>/           # Host-specific configs (infrastructure only)
│   x86/nix-cache/                 # Build server host
│
├── modules/nixos/core/            # Core NixOS (imports scanPaths + DE conditionals)
├── modules/nixos/hardware/        # Audio, GPU, input
├── modules/nixos/services/        # AI, gaming, ddcutil, plymouth
├── modules/nixos/desktop/         # niri/ or plasma/ (mutually exclusive)
│
├── modules/home/core/             # Core user config (imports scanPaths + DE conditionals)
├── modules/home/desktop/          # niri/ or plasma/
├── modules/home/gaming/           # Game overlays
├── modules/home/utilities/        # xdg, mullvad
├── modules/home/users/ryan/       # User-specific overrides (imports core)
└── modules/home/hosts/<name>/     # Host-specific user config
```

**Key patterns:**

- `lib.custom.scanPaths ./.` — recursively imports `.nix` files (skips `default.nix`)
- `lib.custom.relativeToRoot "path"` — resolves paths relative to flake root
- Spec/Impl: `modules/global/*-spec.nix` defines types, `lib/*.nix` provides values
- Desktop environments are mutually exclusive (Plasma vs Niri)
- `host` attrset flows from `lib/hosts.nix` through `specialArgs` into all modules
- Secrets are sops-nix only (per-host `secrets.yaml` + a common `secrets/common.yaml`), decrypted at activation time — never baked into the Nix store

## Commands

```bash
# Enter dev shell (sets FLAKE=$PWD)
nix develop

# Build a host (from flake root)
nixos-rebuild switch --flake .#loki
nh os switch . --hostname loki

# Home-manager switch
home-manager switch --flake .

# Check flake
nix flake check

# Update flake inputs
nix flake update

# Rebuild from cache server revision (ensures binary cache hit)
scripts/nix/upgrade-from-cache.sh
```

## Gotchas

- **`lib.custom` in home-manager**: Available in both NixOS and home-manager modules via the extended `lib` in `specialArgs` (`modules/flake/nixos.nix:69`). Not in `extraSpecialArgs` — it's on `lib.custom`, not a standalone arg.
- **Hardcoded `nh` flake path**: `modules/nixos/core/default.nix:65` has `flake = "/home/ryan/git/dot.nix/"`. This breaks on other machines.
- **`FLAKE` env var**: Set to `/repo/Nix/dot.nix` in `modules/home/core/default.nix:31`, not `$PWD`. This is the host's expected mount point.
- **Desktop envs are mutually exclusive**: A host cannot have both `plasma` and `niri` enabled (assertion in `host-spec.nix`).
- **`scanPaths` skips `default.nix`**: When using `lib.custom.scanPaths`, `default.nix` files are excluded from auto-import. They must be imported explicitly.
- **`neovim.nix` is a redirect**: `modules/home/core/neovim.nix` just does `{ imports = [ ./neovim ]; }`. The actual config is in `modules/home/core/neovim/`.
- **`lib/hosts.nix` has no secrets**: Only non-sensitive host data goes here. SSH keys, passwords, tokens are sops-nix secrets (`hosts/<platform>/<hostname>/secrets.yaml` or `secrets/common.yaml`).
- **Cache server**: Local Nix cache at `10.0.10.14:5000`. The `upgrade-from-cache.sh` script fetches the cached revision and rebuilds with it.
- **`nixos-rebuild` needs `--use-remote-sudo` for remote hosts**.
- **`nh os switch . --hostname <host>`** is the recommended local rebuild command (from devshell).
- **Gaming packages**: `wineWow64Packages.full` (not `wineWowPackages.full`).
- **Nixpkgs channel**: Uses `nixos-unstable` as primary, with `nixos-25.11` (stable) and `nixos-unstable` (unstable) overlays for `stable` and `unstable` attribute sets.
- **State version**: `25.11` for NixOS, `25.05` for home-manager.

## MCP

Configured `mcp-nixos` via `opencode.json`. **Always use it for NixOS/Home Manager lookups** — never hallucinate option names or package attributes.

- **NixOS options**: `mcp-nixos` → `nix` tool with `action=search`, `type=options`, `source=nixos`
- **NixOS packages**: `mcp-nixos` → `nix` tool with `action=search`, `type=packages`, `source=nixos`
- **Home Manager options**: `mcp-nixos` → `nix` tool with `action=search`, `source=home-manager`
- **Package info**: `mcp-nixos` → `nix` tool with `action=info`, `type=option`/`package`
