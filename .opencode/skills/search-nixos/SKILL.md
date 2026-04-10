# Skill: search-nixos

## Purpose
Use this skill to verify Nix attribute names, package availability, and module options against the `nixos-unstable` channel using OpenCode's built-in web search.

## Workflow
1. **Query Construction**:
   - For finding packages: Search exactly `"site:search.nixos.org/packages unstable [target]"`
   - For finding options: Search exactly `"site:search.nixos.org/options unstable [target]"`
   - For debugging breaking changes/renames: Search `"site:discourse.nixos.org OR site:github.com/NixOS/nixpkgs [target] changed OR renamed"`
2. **Execution**: Invoke the built-in web search tool with the constructed query.
3. **Validation**: Read the snippet to confirm the exact Nix syntax (e.g., `pkgs.wayland` vs `pkgs.wayland-protocols`). If the search result discusses versions older than 6 months, refine the search to look for more recent context.
4. **Output**: Apply the verified package or option path directly to the declarative configuration.
