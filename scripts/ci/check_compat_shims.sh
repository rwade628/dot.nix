#!/usr/bin/env bash
# Warns (GitHub Actions annotation) for every Compat shim whose unmodified
# package is now in cache.nixos.org on all of its systems - Hydra builds it
# again, so the shim in modules/flake/overlays.nix can likely be deleted.
# Never fails the job: a lookup error is a warning too.
set -uo pipefail

shims=$(nix eval --json .#lib.compatShims) || {
  echo "::warning::could not evaluate .#lib.compatShims"
  exit 0
}

for name in $(jq -r 'keys[]' <<<"$shims"); do
  removable=true
  for system in $(jq -r --arg n "$name" '.[$n][]' <<<"$shims"); do
    # Darwin hosts build from the nixpkgs-darwin input (see flake.nix).
    input=nixpkgs
    [[ $system == *-darwin ]] && input=nixpkgs-darwin
    out=$(nix eval --raw --inputs-from . "${input}#legacyPackages.${system}.${name}.outPath") || {
      echo "::warning::compat shim '${name}': could not evaluate unmodified package on ${system}"
      removable=false
      continue
    }
    hash=$(basename "$out" | cut -d- -f1)
    if curl -sf -o /dev/null "https://cache.nixos.org/${hash}.narinfo"; then
      echo "compat shim '${name}': unmodified package cached on ${system}"
    else
      echo "compat shim '${name}': unmodified package still uncached on ${system}"
      removable=false
    fi
  done
  if $removable; then
    echo "::warning::compat shim '${name}' looks removable: cache.nixos.org now has the unmodified package on every system it covers (modules/flake/overlays.nix)"
  fi
done
