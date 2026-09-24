# Defines overlays/custom modifications to upstream packages
{
  inputs,
  lib,
  self,
  ...
}:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };

  # Adds custom packages from pkgs directory
  additions =
    final: prev:
    let
      packages = prev.lib.packagesFromDirectoryRecursive {
        callPackage = prev.lib.callPackageWith final;
        directory = customLib.relativeToRoot "pkgs";
      };
    in
    packages;

  # Linux-specific modifications
  linuxModifications = final: prev: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux { };

  # General modifications to existing packages
  modifications = final: prev: {
    # Compat shim: nixpkgs retired buildGo125Module (Go 1.25 EOL, 2026-09-15)
    # faster than sops-nix's pkgs/sops-install-secrets/default.nix, which
    # still calls it directly upstream. Remove once sops-nix bumps its Go
    # builder past this.
    buildGo125Module = prev.buildGo126Module;

    # Track claude-code's own release channel instead of waiting for nixpkgs
    # to catch up (usually a day or two behind). Upstream already ships a
    # prebuilt, zstd-compressed binary per platform, so this overrides only
    # `version` + `src` and inherits nixpkgs' autoPatchelf/wrapProgram work
    # (ripgrep, bubblewrap, socat, DISABLE_AUTOUPDATER, ...) rather than
    # reimplementing it. Bumped nightly by scripts/ai/update_overrides.py -
    # keep the attribute names below in sync if you edit this block.
    claude-code =
      let
        # claude-code-pin-start
        version = "2.1.281";

        platforms = {
          x86_64-linux = "linux-x64";
          aarch64-darwin = "darwin-arm64";
        };

        hashes = {
          x86_64-linux = "sha256-T/ufa6raTYi72MWGdz79BgXFJMejHMODPu2iKXF6eyU=";
          aarch64-darwin = "sha256-BWZipOOlyjd3BzClk0XRtXlu9lREwyuX0jZlGraPP6E=";
        };
        # claude-code-pin-end

        system = prev.stdenv.hostPlatform.system;
      in
      # Only the two systems any host actually uses are pinned; anything else
      # falls through to nixpkgs' own claude-code rather than failing to eval.
      if !(platforms ? ${system}) then
        prev.claude-code
      else
        prev.claude-code.overrideAttrs {
          inherit version;
          src = prev.fetchurl {
            url = "https://downloads.claude.ai/claude-code-releases/${version}/${platforms.${system}}/claude.zst";
            hash = hashes.${system};
          };
        };
  };

  # Stable channel packages
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Unstable channel packages
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
in
{
  flake.overlays = {
    default =
      final: prev:
      (additions final prev)
      // (modifications final prev)
      // (linuxModifications final prev)
      // (stable-packages final prev)
      // (unstable-packages final prev);
  };
}
