# Skill: debug-system

## Purpose

A step-by-step playbook for diagnosing NixOS build errors, Home Manager conflicts, and Linux system runtime issues (like graphical crashes or kernel errors).

## Workflow

1. **Build Diagnostics (NixOS / Home Manager)**:
   - If `nixos-rebuild switch` or `home-manager switch` fails, re-run the command appending the `--show-trace` flag.
   - Analyze the bottom-most stack trace first to identify the exact file and line number causing the evaluation error.
2. **System & Kernel Diagnostics**:
   - For runtime crashes, sleep/wake issues, or service failures, inspect the systemd logs: `journalctl -xe --no-pager | tail -n 50`.
   - For hardware, display (e.g., Wayland/X11, HDR), or driver errors, check the kernel ring buffer: `dmesg -T | tail -n 50`.
   - For isolated user-service issues (managed by Home Manager), check: `journalctl --user -xe`.
3. **Resolution Strategy**:
   - Map the failing unit or error back to its declarative source in the repository.
   - If an error appears to be an upstream bug in `unstable`, use web search to check for current workarounds or pending pull requests on the `nixpkgs` repository before attempting to write a complex local patch.
