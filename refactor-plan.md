# NixOS Repository Refactoring Plan

## Overview

This document outlines a comprehensive refactoring plan to improve the organization of the NixOS repository following NixOS best practices and the dendritic pattern, while maintaining the flake-parts architecture.

## Known Issues to Address (Pre-Refactoring)

1. **Hardcoded flake path**: `modules/nixos/core/default.nix:88` contains `flake = "~/git/dot.nix/";` which will break on other systems. Replace with dynamic path.

2. **Custom library missing in home-manager**: `lib.custom` is only passed to NixOS configurations, not home-manager. Need to add to `modules/flake/nixos.nix` or create separate flake file for home-manager.

3. **Import pattern inconsistency**: Plan previously showed `lib.optionalAttrs` but actual code uses `lib.optional`. Plan updated to reflect correct pattern.

4. **File naming typo**: Plan previously referenced `aluacritty.nix` instead of `alacritty.nix`. Fixed.

5. **Directory vs file confusion**: Gaming and desktop modules are directories with multiple files, not single `.nix` files. Plan updated to reflect this.

## Current State Analysis

### Architecture

- **Flake-parts based**: Uses `hercules-ci/flake-parts` for modular configuration
- **Data-driven**: Specification + Implementation pattern (`modules/global/*-spec.nix` + `lib/*-implementation.nix`)
- **Dendritic structure**: `hosts/<arch>/<host>/` for host-specific configurations
- **Dual configuration**: Separate NixOS and home-manager module trees

### Identified Issues

1. **Package Duplication**: System packages in `modules/nixos/core/default.nix` while home-manager manages similar tools
2. **Fragmented Resources**: Gaming, desktop, and shared configs scattered across directories
3. **Inconsistent Organization**: Mix of DE-based (Niri/Plasma) and function-based (audio, gaming) grouping
4. **Mixed Responsibilities**: Host configs contain both system infrastructure and user-facing settings
5. **Scattered Utilities**: `xdg.nix`, `ddcutil.nix`, `nvtop.nix`, `plymouth.nix` in `modules/home/shared/`

## Refactoring Phases

### Phase 1: Consolidate NixOS System Resources

**Goal**: Move all NixOS system packages and services to organized, single-location modules.

#### New Structure

```
modules/nixos/
├── core/
│   ├── default.nix          # Core system config (imports below)
│   ├── base.nix             # Base system: users, nix, ssh, gnupg
│   ├── packages.nix         # ALL system packages (consolidated)
│   └── system-services.nix  # Systemd services
├── hardware/
│   ├── audio.nix            # PipeWire, alsa (from shared)
│   ├── gpu.nix              # GPU drivers
│   └── input.nix            # Input devices
├── services/
│   ├── display.nix          # Display server base (Niri/Plasma)
│   ├── gaming.nix           # ALL gaming: Steam, Lutris, Sunshine, GameMode
│   ├── ai.nix               # AI tools (from shared)
│   ├── ddcutil.nix          # Monitor controls (system-level)
│   └── plymouth.nix         # Boot theme (system-level)
└── desktop/
    ├── niri.nix             # Niri-specific system config
    └── plasma.nix           # Plasma-specific system config (SDDM, etc.)
```

#### Migration Tasks

- [x] Move `modules/nixos/shared/audio.nix` → `modules/nixos/hardware/audio.nix`
- [x] Move `modules/nixos/shared/gaming/` directory → `modules/nixos/services/gaming/` (keep as directory with steam.nix, lutris.nix, etc.)
- [x] Move `modules/nixos/shared/desktop/niri/` directory → `modules/nixos/desktop/niri/` (keep greeter.nix, nautilus.nix as submodules)
- [x] Move `modules/nixos/shared/desktop/plasma/plasma.nix` → `modules/nixos/desktop/plasma/default.nix`
- [x] Consolidate all packages from `modules/nixos/core/default.nix` into `modules/nixos/core/packages.nix`
- [x] Update all import paths
- [ ] Ensure `custom` library is passed to home-manager via specialArgs

#### Expected Outcome

- Clear separation: base system, hardware, services, desktop environments
- All gaming config in one location
- Desktop environments grouped logically
- Simplified module imports

#### Notes

- `ddcutil.nix` and `plymouth.nix` remain in `modules/nixos/services/` because they configure system-level services (hardware.i2c, services.udev, services.plymouth)
- Plasma directory structure: `modules/nixos/desktop/plasma/default.nix` (not `plasma.nix`)

### Phase 2: Consolidate Home-Manager Resources

**Goal**: Create unified home-manager module structure mirroring NixOS organization.

#### New Structure

```
modules/home/
├── core/
│   ├── default.nix          # Core home config (imports below)
│   ├── base.nix             # Base: shell, git, ssh, direnv
│   ├── packages.nix         # User packages (avoiding NixOS dupes)
│   └── applications.nix     # Apps: neovim, btop, fastfetch
├── desktop/
│   ├── niri/
│   │   ├── default.nix      # Niri WM config
│   │   ├── binds.nix        # Keybindings
│   │   ├── theme-spec.nix   # Matugen theming
│   │   └── programs/        # DE-specific apps (dms, vicinae)
│   └── plasma/
│       ├── default.nix      # Plasma config
│       └── programs/        # Plasma-specific apps
├── gaming/
│   └── mangohud.nix         # Gaming overlays
├── utilities/
│   ├── xdg.nix              # XDG config dirs
└── users/
    └── ryan/
        └── default.nix      # User-specific overrides
```

#### Migration Tasks

- [x] Move `modules/home/shared/gaming/*` → `modules/home/gaming/`
- [x] Move `modules/home/shared/desktop/niri/*` → `modules/home/desktop/niri/` (verify structure)
- [x] Move `modules/home/shared/desktop/plasma/*` → `modules/home/desktop/plasma/`
- [x] Move `modules/home/shared/xdg.nix` → `modules/home/utilities/`
- [ ] Create `modules/home/core/packages.nix` for user packages
- [x] Update all import paths
- [ ] Coordinate package definitions with NixOS to avoid duplication
- [ ] Ensure `custom` library is passed to home-manager via specialArgs in flake.nix

#### Expected Outcome

- Mirrors NixOS organization for consistency
- Desktop environments grouped with clear separation
- Utilities consolidated in single location
- Clear ownership of user packages

#### Notes

- `ddcutil.nix` and `plymouth.nix` moved to `modules/nixos/services/` (system-level services)
- Only `xdg.nix` remains in home-manager utilities (user-level XDG config)

### Phase 3: Reorganize Host Configuration

**Goal**: Keep host-specific configs minimal and focused on infrastructure.

#### New Structure

```
hosts/x86/nixos/
├── default.nix              # Host imports (keep minimal)
├── hardware.nix             # Hardware: kernel, boot, GPU (keep)
├── networking.nix           # Network: systemd-networkd, firewall (keep)
├── mounts.nix               # Mounts: NFS (keep)
├── monitor.nix              # Display config (keep)
└── overrides.nix            # Host-specific package/service overrides
```

#### Migration Tasks

- [x] Rename `shortcuts.nix` → `overrides.nix` (triggerhappy monitor switching)
- [ ] Move `services.nix` content to `modules/nixos/services/`
- [x] Create `overrides.nix` for host-specific customizations
- [x] Keep only infrastructure concerns in host folder
- [x] Update host imports in `hosts/x86/nixos/default.nix`
- [ ] Fix hardcoded flake path in `modules/nixos/core/default.nix:88` - replace with dynamic path using `builtins.getEnv "HOSTNAME"` or similar approach

#### Expected Outcome

- Host configs focus on infrastructure only
- User-facing configs moved to modules
- Easier to add new hosts (minimal duplication)
- Clear separation: infrastructure vs configuration

#### Notes

- `shortcuts.nix` renamed to `overrides.nix` and contains triggerhappy monitor switching (host-specific)
- Host imports updated to point to new module locations

### Phase 4: Resolve Package Duplication

**Goal**: Define packages once with clear ownership (system vs user).

#### Strategy

1. **System Packages** (NixOS): Installed for all users at system level
   - Base tools: `git`, `curl`, `wget`, `jq`, `openssh`
   - Package managers: `cachix`, `bun`
   - Editors: `micro`
   - File managers: `yazi`, `superfile`
   - Gaming: `wineWowPackages.full`, `winetricks`
   - AI: `llama-cpp`

2. **User Packages** (home-manager): User-specific applications
   - Browsers: `librewolf`, `chromium`
   - IDEs: `neovim`
   - Utilities: `fastfetch`, `btop`

3. **Shared Packages**: Use `config.lib.nixpkgs.packageOverrides` for version pinning

#### Implementation Pattern

```nix
# modules/nixos/core/packages.nix
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Base system tools
    git curl wget jq openssh pciutils ethtool sshfs

    # Package managers
    cachix bun

    # Editors
    micro

    # File managers
    yazi superfile

    # Gaming
    wineWowPackages.full winetricks

    # AI
    llama-cpp
  ];
}

# modules/home/core/packages.nix
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # User-specific apps (avoiding system dupes)
    librewolf
    # ... other user apps
  ];
}
```

#### Migration Tasks

- [ ] Document package ownership in `modules/nixos/core/packages.nix`
- [ ] Remove duplicate packages from home-manager
- [ ] Add comments explaining package ownership
- [ ] Create `modules/nixos/core/package-overrides.nix` for version pinning

#### Expected Outcome

- Clear package ownership (system vs user)
- No duplication between NixOS and home-manager
- Easy to audit what packages are installed where
- Version pinning centralized

### Phase 5: Standardize Module Imports

**Goal**: Consistent import patterns across all modules.

#### Pattern for `modules/nixos/core/default.nix`

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = lib.flatten [
    # Base system
    ./base.nix
    ./packages.nix
    ./system-services.nix

    # Desktop environment (conditional)
    (lib.optional (config.host.niri or false) ./desktop/niri/default.nix)
    (lib.optional (config.host.plasma or false) ./desktop/plasma/default.nix)

    # Services
    ./services/gaming/*.nix
    ./services/ai.nix
  ];
}
```

**Note**: Use `lib.optional` (not `lib.optionalAttrs`) for conditional imports when the path is a single file. Use `lib.optionalAttrs` for directory imports or when you need to conditionally include multiple files.

#### Pattern for `modules/home/core/default.nix`

```nix
{ config, lib, pkgs, ... }:

{
  imports = lib.flatten [
    # Base home config
    ./base.nix
    ./packages.nix
    ./applications.nix

    # Desktop environment (conditional)
    (lib.optional (config.host.niri or false) ./desktop/niri/default.nix)
    (lib.optional (config.host.plasma or false) ./desktop/plasma/default.nix)

    # Utilities
    ./utilities/alacritty.nix
    ./utilities/atuin.nix
    ./utilities/ddcutil.nix
    ./utilities/nvtop.nix
    ./utilities/plymouth.nix

    # Gaming
    ./gaming/mangohud.nix
  ];
}
```

**Note**: Ensure `custom` library is passed via `specialArgs` in flake configuration:

```nix
specialArgs = {
  inherit lib custom;
  # ... other args
};
```

#### Migration Tasks

- [ ] Update `modules/nixos/core/default.nix` imports
- [ ] Update `modules/home/core/default.nix` imports
- [ ] Add comments explaining import structure
- [ ] Document import patterns in AGENTS.md
- [ ] Fix hardcoded flake path in `modules/nixos/core/default.nix:88`
- [ ] Add `custom` to `specialArgs` for home-manager configurations

#### Expected Outcome

- Consistent import patterns
- Clear separation of concerns
- Easy to understand module dependencies
- Simplified maintenance

## Benefits of This Refactoring

1. **Clear Mental Model**: System vs user, hardware vs services, desktop environments grouped logically
2. **Easier Discovery**: All gaming config in one place, all desktop config in another
3. **Reduced Duplication**: Packages defined once with clear ownership
4. **Better Scalability**: Adding new desktop environment or service is straightforward
5. **Maintains Dendritic Pattern**: Spec/impl separation, host-specific minimal configs
6. **Preserves Flake-Parts**: No changes to flake structure, only module reorganization
7. **Improved Maintainability**: Easier to find and modify specific resources

## Timeline and Risk Assessment

### Estimated Timeline

- **Phase 1**: 2-3 hours (NixOS consolidation)
- **Phase 2**: 2-3 hours (Home-manager consolidation)
- **Phase 3**: 1-2 hours (Host reorganization)
- **Phase 4**: 1 hour (Package deduplication)
- **Phase 5**: 1 hour (Import standardization)

**Total**: ~7-10 hours

### Risk Assessment

**Low Risk**:

- File moves (straightforward with import updates)
- Module reorganization (no functional changes)
- Import path updates (testing will catch errors)

**Medium Risk**:

- Package deduplication (need to test both NixOS and home-manager)
- Host configuration changes (need to verify all hosts still build)

**Mitigation Strategies**:

1. Create backup branch before starting
2. Test each phase independently with `nix flake check`
3. Build each host after Phase 3
4. Verify both NixOS and home-manager configurations after Phase 4
5. Document any breaking changes in AGENTS.md

## Pre-Implementation Checklist

Before starting the refactoring:

- [ ] Create backup branch (`git checkout -b refactor/pre-module-organization`)
- [ ] Ensure all current configurations build successfully (`nix flake check`)
- [ ] Verify `custom` library is properly passed to both NixOS and home-manager configurations
- [ ] Document any host-specific customizations
- [ ] Review package list to identify duplicates
- [ ] Prepare AGENTS.md with new structure

## Post-Implementation Checklist

After completing the refactoring:

- [x] All hosts build successfully (`nix flake check`) - **Phase 1-3 complete**
- [ ] Home-manager configurations apply successfully (`home-manager switch`)
- [ ] AGENTS.md updated with new structure
- [ ] README.md updated if needed
- [ ] Commit changes with clear commit messages
- [ ] Document any breaking changes in commit messages
- [ ] Verify `custom.relativeToRoot` works correctly for all imports
- [ ] Confirm no hardcoded paths remain (e.g., `~/git/dot.nix/`)

---

## Current Status

### Completed (Phases 1-3)

- [x] NixOS module reorganization: `hardware/`, `services/`, `desktop/` directories created
- [x] Home-manager module reorganization: `desktop/`, `gaming/`, `utilities/` directories created
- [x] Host configuration: `overrides.nix` created from `shortcuts.nix`
- [x] Import paths updated in `modules/nixos/core/default.nix` and `hosts/x86/nixos/default.nix`
- [x] `nix flake check` passes with no errors

### Remaining (Phases 4-5)

- [ ] Resolve package duplication between NixOS and home-manager
- [ ] Standardize module imports with consistent patterns
- [ ] Fix hardcoded flake path in `modules/nixos/core/default.nix:88`
- [ ] Add `custom` library to home-manager `specialArgs`
- [ ] Update AGENTS.md with new structure

---

*Last updated: March 2026*
