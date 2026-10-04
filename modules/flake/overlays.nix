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

  # Compat shims (see CONTEXT.md): each works around a temporary upstream
  # breakage on the listed systems only. The nightly CI job
  # (scripts/ci/check_compat_shims.sh) evaluates the unmodified package for
  # each of those systems and warns once cache.nixos.org has it - i.e. once
  # Hydra builds it again and the shim can be deleted.
  compatShims = {
    # TEST ONLY - identity shim on a package Hydra caches, to exercise the
    # CI warning path. Reverted in the next commit.
    hello = {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      apply = prev: prev.hello;
    };

    # ltrace 0.7.91 builds fine under GCC 16 but 15 of its testsuite cases
    # fail, so Hydra never caches it.
    ltrace = {
      systems = [ "x86_64-linux" ];
      apply = prev: prev.ltrace.overrideAttrs { doCheck = false; };
    };
  };

  shimModifications =
    final: prev:
    lib.mapAttrs (_: shim: shim.apply prev) (
      lib.filterAttrs (
        _: shim: builtins.elem prev.stdenv.hostPlatform.system shim.systems
      ) compatShims
    );

  # General modifications to existing packages
  modifications = final: prev: {
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
        version = "2.1.289";

        platforms = {
          x86_64-linux = "linux-x64";
          aarch64-darwin = "darwin-arm64";
        };

        hashes = {
          x86_64-linux = "sha256-ZvcqhopCyhDlRiq3ioj9n1V2SG9ZsyoK/FkQq0tzt2U=";
          aarch64-darwin = "sha256-REBLOGwwvhBlM7vSYLaJ0izttpVqaucBGLqWoycRqCs=";
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
  # Shim names -> systems, for scripts/ci/check_compat_shims.sh.
  flake.lib.compatShims = lib.mapAttrs (_: shim: shim.systems) compatShims;

  flake.overlays = {
    default =
      final: prev:
      (additions final prev)
      // (modifications final prev)
      // (shimModifications final prev)
      // (stable-packages final prev)
      // (unstable-packages final prev);
  };
}
