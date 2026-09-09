#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "requests",
# ]
# ///
"""Update package versions in package-overrides.nix by fetching latest GitHub releases."""

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import requests

DUMMY_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


@dataclass
class Package:
    name: str
    owner: str
    repo: str
    tag_prefix: str
    version_pattern: re.Pattern
    semver: bool = False
    hash_count: int = 1


PACKAGES = [
    Package(
        name="llama-cpp",
        owner="ggml-org",
        repo="llama.cpp",
        tag_prefix="b",
        version_pattern=re.compile(
            r'(llama-cpp\s*=\s*.*?version\s*=\s*")(\d+)(";)', re.DOTALL
        ),
        hash_count=2,  # src hash + npmDepsHash
    ),
    Package(
        name="llama-swap",
        owner="mostlygeek",
        repo="llama-swap",
        tag_prefix="v",
        version_pattern=re.compile(
            r"(https://github\.com/mostlygeek/llama-swap/releases/download/v)(\d+)(/llama-swap_)(\d+)(_linux_amd64\.tar\.gz)"
        ),
    ),
]


def parse_semver(version_str: str) -> tuple[int, ...] | None:
    """Parse semantic version string into tuple for comparison."""
    version_str = version_str.lstrip("v")
    try:
        return tuple(int(p) for p in version_str.split("."))
    except ValueError:
        return None


def get_latest_release(pkg: Package) -> str | None:
    """Fetch latest release version from GitHub."""
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.repo}/releases"
    try:
        response = requests.get(url)
        response.raise_for_status()
        releases = response.json()
    except Exception as e:
        print(f"Failed to fetch releases for {pkg.owner}/{pkg.repo}: {e}")
        return None

    if pkg.semver:
        max_ver, max_ver_str = (0, 0, 0), None
        for release in releases:
            if release.get("prerelease") or release.get("draft"):
                continue
            tag = release["tag_name"]
            if tag.startswith(pkg.tag_prefix):
                ver_str = tag[len(pkg.tag_prefix) :]
                if (parsed := parse_semver(ver_str)) and parsed > max_ver:
                    max_ver, max_ver_str = parsed, ver_str
        return max_ver_str
    else:
        max_ver = 0
        for release in releases:
            tag = release["tag_name"]
            if tag.startswith(pkg.tag_prefix):
                try:
                    ver = int(tag[len(pkg.tag_prefix) :])
                    max_ver = max(max_ver, ver)
                except ValueError:
                    continue
        return str(max_ver) if max_ver else None


def compare_versions(current: str, latest: str, semver: bool) -> bool:
    """Return True if latest > current."""
    if semver:
        return parse_semver(latest) > parse_semver(current)
    return int(latest) > int(current)


def replace_hashes_in_block(content: str, start: int, count: int) -> str:
    """Replace `count` hash occurrences after `start` position with dummy hash."""
    hash_pattern = re.compile(
        r'((?:hash|vendorHash|npmDepsHash)\s*=\s*")(sha256-[^"]*)(";)'
    )
    pos = start
    for _ in range(count):
        match = hash_pattern.search(content, pos)
        if match:
            content = content[: match.start(2)] + DUMMY_HASH + content[match.end(2) :]
            pos = match.start(2) + len(DUMMY_HASH)
    return content


def update_version(content: str, pkg: Package) -> tuple[str, bool]:
    """Update package version and replace hashes with dummy values."""
    print(f"\n--- Checking {pkg.name} ---")

    match = pkg.version_pattern.search(content)
    if not match:
        print(f"Could not find {pkg.name} version definition.")
        return content, False

    current = match.group(2)
    latest = get_latest_release(pkg)

    if not latest:
        return content, False

    print(f"Current: {current}, Latest: {latest}")

    if not compare_versions(current, latest, pkg.semver):
        print("Already up to date.")
        return content, False

    print(f"Updating {pkg.name} to {latest}...")

    # Replace version - handle llama-swap special case (version appears twice in URL)
    if pkg.name == "llama-swap":
        content = pkg.version_pattern.sub(
            rf"\g<1>{latest}\g<3>{latest}\g<5>", content
        )
    else:
        content = pkg.version_pattern.sub(rf"\g<1>{latest}\g<3>", content)

    # Replace hashes with dummy. Ollama's llama.cpp pin lives before the
    # override block and is handled by update_ollama_llama_cpp_pin().
    updated_match = pkg.version_pattern.search(content)
    if not updated_match:
        print(f"Could not find updated {pkg.name} version definition.")
        return content, False
    block_hash_count = 2 if pkg.name == "ollama" else pkg.hash_count
    content = replace_hashes_in_block(content, updated_match.start(), block_hash_count)

    return content, True


def get_new_hash(pkg_attribute: str) -> str | None:
    """Build package to extract correct hash from error message."""
    print(f"Building {pkg_attribute} to capture hash...")
    result = subprocess.run(
        [
            "nix", "build",
            f".#nixosConfigurations.loki.pkgs.{pkg_attribute}",
            "--no-link", "--cores", "1",
        ],
        capture_output=True,
        text=True,
    )

    if match := re.search(r"\s+got:\s+(sha256-\S+)", result.stderr):
        return match.group(1)

    print(f"Could not extract hash for {pkg_attribute}.")
    return None


def resolve_hashes(file_path: Path, content: str, pkg: Package) -> str:
    """Resolve dummy hashes by building and extracting correct values."""
    for i in range(pkg.hash_count):
        print(f"Resolving {pkg.name} hash {i + 1}/{pkg.hash_count}...")

        new_hash = get_new_hash(pkg.name)
        if not new_hash:
            print(f"Failed to resolve {pkg.name} hash {i + 1}/{pkg.hash_count}.")
            sys.exit(1)

        print(f"Found hash: {new_hash}")
        content = content.replace(DUMMY_HASH, new_hash, 1)
        file_path.write_text(content)

    print(f"Successfully updated {pkg.name}.")
    return content


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


def main():
    file_path = Path("hosts/x86/loki/package-overrides.nix")
    if not file_path.exists():
        print(f"Error: {file_path} not found.")
        sys.exit(1)

    content = file_path.read_text()

    for pkg in PACKAGES:
        content, updated = update_version(content, pkg)
        if updated:
            file_path.write_text(content)
            content = resolve_hashes(file_path, content, pkg)

    update_talosctl()


if __name__ == "__main__":
    main()
