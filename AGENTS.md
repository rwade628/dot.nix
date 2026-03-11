# AGENTS.md - NixOS Repository Guide

## Overview

This document provides guidance for working with the NixOS dotfiles repository, following flake-parts architecture and NixOS best practices.

## Repository Structure

```
dot.nix/
├── flake.nix                    # Flakes configuration + inputs
├── flake.lock
├── lib/
│   ├── default.nix               # Custom Nix library functions
│   ├── hosts.nix                # Host data implementation
│   └── secrets.nix              # Secrets implementation
├── modules/
│   ├── flake/                   # Flake-specific modules
│   │   ├── devshell.nix
│   │   ├── nixos.nix
│   │   ├── overlays.nix
│   │   └── packages.nix
│   ├── global/                  # Shared specs (host-spec, secret-spec)
│   ├── nixos/                    # NixOS system modules
│   │   ├── core/                 # Core NixOS configuration
│   │   └── shared/               # Shared NixOS modules
│   ├── home/                     # Home-manager modules
│   │   ├── core/                # Core home-manager config
│   │   ├── shared/               # Shared home-manager modules
│   │   └── users/
│   ├── devshell.nix
│   └── packages.nix
├── hosts/
│   └── x86/
│       ├── nix-cache/
│       └── nixos/
│           ├── default.nix
│           ├── hardware.nix
│           ├── networking.nix
│           └── ...
├── pkgs/
│   └── wine-app-wrapper.nix
└── scripts/
```

## Key Patterns

### 1. Specification + Implementation Pattern

The repository uses a data-driven approach where specifications are defined first, then implemented:

**Specifications** (`modules/global/`):

- `host-spec.nix`: Defines host configuration schema
- `secret-spec.nix`: Defines secrets schema

**Implementations** (`lib/`):

- `hosts.nix`: Provides host data implementation
- `secrets.nix`: Provides secrets implementation

**Access**: Both are evaluated together via `lib.evalModules`

### 2. Flake-Parts Architecture

- Uses `hercules-ci/flake-parts` for modular configuration
- Modular imports via `flake-parts.lib.mkFlake`
- Each module is independent and composable
- No monolithic configuration files

### 3. Dendritic Structure

- `hosts/<arch>/<host>/` for host-specific configurations
- Architecture-based organization (x86, arm, etc.)
- Minimal duplication between hosts
- Conditional module loading based on host spec

## Module Organization Guidelines

### NixOS System Modules

**Location**: `modules/nixos/`

**Categories**:

- `core/`: Base system configuration (users, nix, ssh, gnupg)
- `hardware/`: Hardware-specific (audio, gpu, input)
- `services/`: Systemd services (display, gaming, ai) - OPTIONAL modules
- `desktop/`: Desktop environment system config (niri, plasma)

**Rules**:

- System packages go in `core/packages.nix`
- Services go in `services/*.nix` - all services are optional
- Desktop environments go in `desktop/*.nix` (system-level)
- Hardware goes in `hardware/*.nix`
- Use `lib.custom.scanPaths` for module imports
- Use `lib.custom.relativeToRoot` for file paths

### Home-Manager Modules

**Location**: `modules/home/`

**Categories**:

- `core/`: Core home config (shell, git, ssh, direnv)
- `desktop/`: Desktop environment user config (niri, plasma)
- `gaming/`: Gaming-specific configurations
- `utilities/`: Utility applications (terminal, monitoring, etc.)
- `users/`: User-specific overrides

**Rules**:

- User packages go in `core/packages.nix`
- Desktop environments go in `desktop/*` (user-level)
- Utilities go in `utilities/*.nix`
- Gaming goes in `gaming/*.nix`
- Use `lib.custom.scanPaths` for module imports
- Use `lib.custom.relativeToRoot` for file paths

### Shared/Optional Modules

**Location**: `modules/nixos/shared/` and `modules/home/shared/`

**Rules**:

- Modules in `/shared/` are optional, NOT required for all hosts
- Always use `lib.mkEnableOption` for optional modules
- Use conditional imports: `(lib.optionalAttrs (config.host.enableFeature or false) ./path/to/module.nix)`
- Prefer separate modules over shared to avoid duplication
- Each shared module should have clear enable option

### Host Configuration

**Location**: `hosts/<arch>/<host>/`

**Rules**:

- Keep infrastructure only: hardware, networking, mounts
- Move user-facing configs to modules
- Use `overrides.nix` for host-specific customizations
- Minimal duplication between hosts
- DE-specific configs stay with DE module (e.g., Plasma shortcuts)
- Use `lib.custom.relativeToRoot` for module imports

## Adding New Resources

### Adding a New Service

**For NixOS**:

1. Create `modules/nixos/services/my-service.nix`
2. Add to `core/default.nix` via `lib.custom.scanPaths`
3. Document in AGENTS.md
4. Mark as optional if needed: use `lib.mkEnableOption`

**For Home-Manager**:

1. Create `modules/home/utilities/my-service.nix` (or appropriate category)
2. Add to `core/default.nix` via `lib.custom.scanPaths`
3. Document in AGENTS.md

### Adding a New Desktop Environment

**For NixOS**:

1. Create `modules/nixos/desktop/myde.nix`
2. Add to `core/default.nix` with conditional: `(lib.optionalAttrs (config.host.myde or false) ./desktop/myde.nix)`

**For Home-Manager**:

1. Create `modules/home/desktop/myde/default.nix`
2. Add to `core/default.nix` with conditional: `(lib.optionalAttrs (config.host.myde or false) ./desktop/myde/default.nix)`

### Adding a New Package

**System Packages** (NixOS):

- Add to `modules/nixos/core/packages.nix`
- Document ownership in comments

**User Packages** (Home-Manager):

- Add to `modules/home/core/packages.nix`
- Avoid duplicates from NixOS packages
- Document ownership in comments

## NixOS Best Practices

### 1. Modular Configuration

- Break down complex configurations into smaller modules
- Each module should have a single responsibility
- Use `imports` to compose modules
- Use `lib.custom.scanPaths` for module imports

### 2. Conditional Configuration

```nix
# Use lib.optionalAttrs for optional modules
(lib.optionalAttrs (config.host.feature or false) ./path/to/module.nix)

# Use lib.mkIf for single conditional
(lib.mkIf (config.host.feature or false) {
  # configuration
})

# Use lib.mkEnableOption for optional modules
options.myModule.enable = lib.mkEnableOption "Enable my module";

config = lib.mkIf config.myModule.enable {
  # module configuration
}
```

### 3. Library Function Usage

**Never hardcode file paths. Always use library functions:**

```nix
{ config, lib, pkgs, ... }:

{
  imports = lib.custom.scanPaths [ ./core ./hardware ./services ./desktop ];

  # Use relativeToRoot for specific files
  hardware.audio = import (lib.custom.relativeToRoot ./modules/nixos/hardware/audio.nix) { inherit config lib pkgs; };
}
```

### 4. Package Management

- System packages: `environment.systemPackages`
- User packages: `home.packages`
- Avoid duplication between system and user packages
- Document package ownership in comments

### 5. Secret Management

- Secrets defined in `modules/global/secret-spec.nix`
- Implementation in `lib/secrets.nix`
- Never commit secrets to repository
- Use agenix or similar for runtime secrets

### 6. Hardware Configuration

- Keep hardware-specific configs in `modules/nixos/hardware/`
- Use `hardware.nix` for kernel, boot, GPU
- Use architecture-specific overrides if needed

### 7. Optional Modules

- All modules in `modules/nixos/shared/` and `modules/home/shared/` are optional
- Always use `lib.mkEnableOption` for optional modules
- Use conditional imports to avoid loading unnecessary modules
- Example:

  ```nix
  options.ai.enable = lib.mkEnableOption "Enable AI tools";
  config = lib.mkIf config.ai.enable {
    # AI configuration
  }
  ```

### 8. Desktop Environment Specifics

- DE-specific configs (shortcuts, themes, etc.) stay with DE module
- Example: Plasma shortcuts go in `modules/home/shared/desktop/plasma/`
- Don't move DE-specific configs to host directory

## Flake-Parts Specific Guidelines

### 1. Module Structure

Each module should export a single NixOS module:

```nix
{ config, lib, pkgs, ... }:

{
  options.myModule.enable = lib.mkEnableOption "Enable my module";
  config = lib.mkIf config.myModule.enable {
    # module configuration
  };
}
```

### 2. Flake Inputs

- Use stable channel for NixOS (nixos-25.11)
- Use unstable channel for packages (nixpkgs-unstable)
- Home-manager follows nixpkgs release
- Document all inputs in flake.nix

### 3. Flake Outputs

- System configurations: `flake.nixosConfigurations`
- Home configurations: `homeConfigurations` (if using flakes)
- Use `mkHostConfigs` helper from flake-parts

### 4. Module Import Patterns

**For NixOS core modules:**

```nix
{ config, lib, pkgs, ... }:

{
  imports = lib.custom.scanPaths [ ./core ./hardware ./services ./desktop ];
}
```

**For Home-Manager core modules:**

```nix
{ config, lib, pkgs, ... }:

{
  imports = lib.custom.scanPaths [ ./core ./applications ./desktop ./utilities ./gaming ];
}
```

**For specific file imports:**

```nix
{ config, lib, pkgs, ... }:

{
  # Use relativeToRoot for specific files
  hardware.audio = import (lib.custom.relativeToRoot ./modules/nixos/hardware/audio.nix) { inherit config lib pkgs; };
}
```

## Common Workflows

### Building a Single Host

```bash
nix build .#nixosConfigurations.myhost.config.system.build.toplevel
```

### Testing Home-Manager

```bash
home-manager switch --flake .#myhost@ryan
```

### Running Flake Checks

```bash
nix flake check
```

### Building All Hosts

```bash
nix build .#nixosConfigurations
```

### Updating Dependencies

```bash
nix flake update
```

## Code Quality Standards

### Naming Conventions

- Files: lowercase with hyphens (`my-service.nix`)
- Modules: PascalCase (`MyService`)
- Functions: snake_case (`my_function`)
- Variables: camelCase or snake_case (prefer snake_case)

### Code Organization

1. Import statements first
2. Options definition
3. Configuration
4. Comments explaining complex logic

### Comments

- Add comments for complex logic
- Document package ownership
- Explain conditional branches
- Keep comments concise

## Debugging

### Checking Module Dependencies

```bash
nix flake show
nix eval .#nixosConfigurations.myhost.config --apply builtins.toString
```

### Inspecting Module Options

```bash
nix eval .#nixosConfigurations.myhost.config.options --apply builtins.toString
```

### Checking for Errors

```bash
nix flake check
nixos-rebuild test  # Dry run
```

## Security Considerations

1. **Never commit secrets**: Use agenix or similar
2. **Review package sources**: Only use trusted sources
3. **Limit package scope**: Keep system packages minimal
4. **Audit flake inputs**: Regularly review flake.lock
5. **Use NixOS module security**: Leverage NixOS built-in security

## Contributing Guidelines

1. **Test before committing**: Ensure all hosts build
2. **Follow module organization**: Add to appropriate category
3. **Document changes**: Update AGENTS.md
4. **Use descriptive commit messages**: Explain why, not just what
5. **Review package ownership**: Avoid duplication
6. **Maintain dendritic structure**: Keep host configs minimal

## Version Control

### Git Workflow

- Main branch: `main`
- Feature branches: `refactor/feature-name`
- Never force push to main/master
- Use merge commits for feature branches

### Commit Messages

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Be descriptive: "Add ffmpeg module for video processing"
- Reference issues: "fix: #123 - resolve audio driver issue"

## Maintenance

### Regular Tasks

- Update flake.lock: `nix flake update`
- Review flake inputs: Check for security updates
- Audit packages: Remove unused packages
- Check module imports: Ensure all imports are valid
- Test builds: Build all hosts regularly

### Documentation Updates

- Update AGENTS.md when adding new patterns
- Update REFACTORING_PLAN.md when executing phases
- Document breaking changes in commit messages

## Resources

### Official Documentation

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nixos.wiki/wiki/Home-Manager)
- [Flake Parts Documentation](https://flake.parts/)
- [NixOS Options Search](https://search.nixos.org/options)

### Useful Tools

- `nixos-rebuild`: Rebuild system
- `home-manager`: Home-configuration management
- `nix flake`: Flake operations
- `nix eval`: Evaluate Nix expressions

### Community

- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [r/NixOS](https://reddit.com/r/NixOS)

---

*Last updated: March 2026*
*For questions or suggestions, refer to the main README.md*
