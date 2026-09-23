#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests",
# ]
# ///
"""Bump the pinned, non-flake-input package versions to their latest upstream release.

Each package here ships a prebuilt binary upstream, so a bump is a version
string plus a plain download hash - no `nix build` (and so no darwin builder)
is needed to resolve anything.
"""

import re
import subprocess
import sys
from pathlib import Path

import requests


def parse_semver(version_str: str) -> tuple[int, ...] | None:
    """Parse semantic version string into tuple for comparison."""
    version_str = version_str.lstrip("v")
    try:
        return tuple(int(p) for p in version_str.split("."))
    except ValueError:
        return None


def prefetch_sri(url: str) -> str | None:
    """Download `url` and return its hash in SRI format, without building anything."""
    result = subprocess.run(
        ["nix-prefetch-url", "--type", "sha256", url],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"Failed to prefetch {url}: {result.stderr.strip()}")
        return None
    base32_hash = result.stdout.strip().splitlines()[-1]
    sri = subprocess.run(
        ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", base32_hash],
        capture_output=True, text=True,
    )
    if sri.returncode != 0:
        print(f"Failed to convert hash for {url}: {sri.stderr.strip()}")
        return None
    return sri.stdout.strip()


def update_talosctl() -> None:
    """Update pkgs/talosctl.nix to the latest siderolabs/talos release.

    talosctl ships prebuilt binaries, so each per-system hash is just a
    plain download hash - no nix build (and no darwin builder) required.
    """
    print("\n--- Checking talosctl ---")
    file_path = Path("pkgs/talosctl.nix")
    if not file_path.exists():
        print(f"{file_path} not found, skipping.")
        return

    content = file_path.read_text()

    version_match = re.search(r'version = "([\d.]+)";', content)
    if not version_match:
        print("Could not find talosctl version.")
        return
    current = version_match.group(1)

    try:
        response = requests.get(
            "https://api.github.com/repos/siderolabs/talos/releases/latest"
        )
        response.raise_for_status()
        latest = response.json()["tag_name"].lstrip("v")
    except Exception as e:
        print(f"Failed to fetch latest talos release: {e}")
        return

    print(f"Current: {current}, Latest: {latest}")

    if not (parse_semver(latest) and parse_semver(latest) > parse_semver(current)):
        print("Already up to date.")
        return

    print(f"Updating talosctl to {latest}...")
    content = content.replace(f'version = "{current}";', f'version = "{latest}";', 1)

    asset_pattern = re.compile(
        r'(asset = ")(talosctl-[\w-]+)(";\s*\n\s*hash = ")(sha256-[^"]+)(";)'
    )
    for match in list(asset_pattern.finditer(content)):
        asset, old_hash = match.group(2), match.group(4)
        url = f"https://github.com/siderolabs/talos/releases/download/v{latest}/{asset}"
        new_hash = prefetch_sri(url)
        if not new_hash:
            print(f"Aborting talosctl update; could not resolve hash for {asset}.")
            sys.exit(1)
        content = content.replace(old_hash, new_hash, 1)

    file_path.write_text(content)
    print("Successfully updated talosctl.")


def update_claude_code() -> None:
    """Update the claude-code pin in modules/flake/overlays.nix.

    Upstream publishes a prebuilt, zstd-compressed binary per platform, so
    each hash is a plain download hash - no nix build (and no darwin builder)
    required, same as talosctl. Only the systems listed in the overlay's
    `platforms` table are prefetched; everything else falls through to
    nixpkgs there and needs no hash here.
    """
    print("\n--- Checking claude-code ---")
    file_path = Path("modules/flake/overlays.nix")
    if not file_path.exists():
        print(f"{file_path} not found, skipping.")
        return

    content = file_path.read_text()

    # The pin is delimited by marker comments in the overlay so this only ever
    # rewrites claude-code's own version/hashes, never another package's.
    block_match = re.search(
        r"# claude-code-pin-start\n(.*?)\n\s*# claude-code-pin-end", content, re.DOTALL
    )
    if not block_match:
        print("Could not find the claude-code pin block in overlays.nix.")
        return
    block = block_match.group(1)

    version_match = re.search(r'version = "([\d.]+)";', block)
    if not version_match:
        print("Could not find claude-code version.")
        return
    current = version_match.group(1)

    try:
        response = requests.get(
            "https://downloads.claude.ai/claude-code-releases/latest"
        )
        response.raise_for_status()
        latest = response.text.strip()
    except Exception as e:
        print(f"Failed to fetch latest claude-code release: {e}")
        return

    if not parse_semver(latest):
        print(f"Unexpected claude-code version from upstream: {latest!r}")
        return

    print(f"Current: {current}, Latest: {latest}")

    if not parse_semver(latest) > parse_semver(current):
        print("Already up to date.")
        return

    # Map each nix system to its upstream platform directory, then to the
    # hash line that needs replacing. Both tables are keyed by nix system, so
    # they're zipped by key rather than by position.
    platforms = dict(
        re.findall(r"([\w-]+) = \"([\w-]+)\";", block.split("platforms = {")[1].split("};")[0])
    )
    hash_entries = re.findall(
        r"([\w-]+) = \"(sha256-[^\"]+)\";", block.split("hashes = {")[1].split("};")[0]
    )
    if not platforms or not hash_entries:
        print("Could not parse the claude-code platforms/hashes tables.")
        return

    print(f"Updating claude-code to {latest}...")
    new_block = block.replace(f'version = "{current}";', f'version = "{latest}";', 1)

    for system, old_hash in hash_entries:
        platform = platforms.get(system)
        if not platform:
            print(f"No platform mapping for {system}; aborting claude-code update.")
            sys.exit(1)
        url = (
            "https://downloads.claude.ai/claude-code-releases/"
            f"{latest}/{platform}/claude.zst"
        )
        new_hash = prefetch_sri(url)
        if not new_hash:
            print(f"Aborting claude-code update; could not resolve hash for {platform}.")
            sys.exit(1)
        new_block = new_block.replace(old_hash, new_hash, 1)

    content = content.replace(block, new_block, 1)
    file_path.write_text(content)
    print("Successfully updated claude-code.")


def main():
    update_talosctl()
    update_claude_code()


if __name__ == "__main__":
    main()
