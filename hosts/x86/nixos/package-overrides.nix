# PC-specific package overrides (CUDA, custom packages)
# Note: allowUnfree is set in common/nixpkgs.nix
{ pkgs, ... }:

{
  nixpkgs.config = {
    cudaSupport = true;
    packageOverrides = pkgs: {
      # Override llama-cpp to latest version b6150 with CUDA support
      llama-cpp =
        (pkgs.llama-cpp.override {
          cudaSupport = true;
          rocmSupport = false;
          metalSupport = false;
          # Enable BLAS for optimized CPU layer performance (OpenBLAS)
          # This is crucial for models using split-mode or CPU offloading
          blasSupport = true;
        }).overrideAttrs
          (oldAttrs: rec {
            version = "8746";
            src = pkgs.fetchFromGitHub {
              owner = "ggml-org";
              repo = "llama.cpp";
              tag = "b${version}";
              hash = "sha256-7y9sknnHu4o9bUWIITH5s9Eg3PaUK/oGy52W14szA0E=";
              leaveDotGit = true;
              postFetch = ''
                git -C "$out" rev-parse --short HEAD > $out/COMMIT
                find "$out" -name .git -print0 | xargs -0 rm -rf
              '';
            };

            # FIX: Upstream llama.cpp removed the precompiled index.html.gz file in newer versions.
            # However, the inherited nixpkgs derivation still runs an `rm` command in its postPatch
            # phase to delete it. Creating a dummy file here ensures that inherited `rm` command succeeds.
            prePatch = ''
              ${oldAttrs.prePatch or ""}
              mkdir -p tools/server/public
              touch tools/server/public/index.html.gz
            '';

            # Enable native CPU optimizations for massively better CPU performance
            # This enables AVX, AVX2, AVX-512, FMA, etc. for your specific CPU
            # NOTE: This is intentionally opposite of nixpkgs (which uses -DGGML_NATIVE=off
            # for reproducible builds). We sacrifice portability for faster CPU layers.
            cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
              "-DGGML_NATIVE=ON"
              "-DCMAKE_CUDA_ARCHITECTURES=120" # RTX 5070 TI - needed since sandbox has no GPU
            ];

            # Disable Nix's NIX_ENFORCE_NO_NATIVE which strips -march=native flags
            # See: https://github.com/NixOS/nixpkgs/issues/357736
            # See: https://github.com/NixOS/nixpkgs/pull/377484 (intentionally contradicts this)
            preConfigure = ''
              export NIX_ENFORCE_NO_NATIVE=0
              ${oldAttrs.preConfigure or ""}
            '';
          });

      # llama-swap from GitHub releases
      llama-swap = pkgs.runCommand "llama-swap" { } ''
        mkdir -p $out/bin
        tar -xzf ${
          pkgs.fetchurl {
            url = "https://github.com/mostlygeek/llama-swap/releases/download/v199/llama-swap_199_linux_amd64.tar.gz";
            hash = "sha256-KzGpX/g/zHQ0Mov5uWhx25liSI3h0zseByJ5uUZYilA=";
          }
        } -C $out/bin
        chmod +x $out/bin/llama-swap
      '';
    };
  };
}
