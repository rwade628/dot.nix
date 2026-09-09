# Upstream nixpkgs lags behind Talos releases; track the latest release directly
# from siderolabs until nixpkgs catches up. Bump `version` + hashes to update:
#   nix-prefetch-url https://github.com/siderolabs/talos/releases/download/v<version>/talosctl-<os>-<arch>
{
  stdenvNoCC,
  fetchurl,
  lib,
  installShellFiles,
}:
let
  version = "1.14.0";

  sources = {
    x86_64-linux = {
      asset = "talosctl-linux-amd64";
      hash = "sha256-LBR8SpnRJMlb1cGQ/gVOCzyTSV8iQ/1lLr1COtuDd8c=";
    };
    aarch64-linux = {
      asset = "talosctl-linux-arm64";
      hash = "sha256-GWFeHQ6yIt6G7C8Uh+fW509RcakDjnOurN6Mxkfj2eA=";
    };
    x86_64-darwin = {
      asset = "talosctl-darwin-amd64";
      hash = "sha256-ZWO6pDd071w1Hg2fL9cglBxILaAf467VPulkS1UkU8U=";
    };
    aarch64-darwin = {
      asset = "talosctl-darwin-arm64";
      hash = "sha256-8MZaDpcLbyPPAWDkMudJa6k5V6SfNpeA1OU4iO1m70Y=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "talosctl: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "talosctl";
  inherit version;

  src = fetchurl {
    url = "https://github.com/siderolabs/talos/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  dontUnpack = true;
  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/talosctl
    installShellCompletion --cmd talosctl \
      --bash <($out/bin/talosctl completion bash) \
      --zsh <($out/bin/talosctl completion zsh) \
      --fish <($out/bin/talosctl completion fish)
    runHook postInstall
  '';

  meta = {
    description = "CLI for out-of-band management of Kubernetes nodes created by Talos (pinned ahead of nixpkgs)";
    homepage = "https://www.talos.dev/";
    license = lib.licenses.mpl20;
    mainProgram = "talosctl";
    platforms = builtins.attrNames sources;
  };
}
