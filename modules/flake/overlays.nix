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
  linuxModifications = final: prev: prev.lib.optionalAttrs prev.stdenv.isLinux { };

  # General modifications to existing packages
  modifications = final: prev: {
    # Update Spotify to latest version (upstream is outdated)
    # Check for updates: curl -s -H 'X-Ubuntu-Series: 16' "https://api.snapcraft.io/api/v1/snaps/details/spotify?channel=stable" | jq '.revision,.download_sha512,.version'
    spotify = prev.spotify.overrideAttrs (old: rec {
      version = "1.2.74.477.g3be53afe";
      rev = "89";
      src = prev.fetchurl {
        url = "https://api.snapcraft.io/api/v1/snaps/download/pOBIoZ2LrCB3rDohMxoYGnbN14EHOgD7_${rev}.snap";
        hash = "sha512-mn1w/Ylt9weFgV67tB435CoF2/4V+F6gu1LUXY07J6m5nxi1PCewHNFm8/11qBRO/i7mpMwhcRXaiv0HkFAjYA==";
      };
    });
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
