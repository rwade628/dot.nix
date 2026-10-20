# Keeper Commander (`keeper`), run through uvx at a pinned PyPI release rather
# than packaged from nixpkgs (which lags behind and doesn't package its
# PAM/WebRTC Rust extensions). Bumped nightly by scripts/ai/update_overrides.py
# from PyPI's latest release - only `version` needs to change, there's no hash.
#
# The interpreter is nixpkgs' python313 rather than a uv-downloaded one, so
# it runs the same on NixOS and darwin. 3.13 rather than the default python3:
# keeper-mlkem only ships wheels up to cp313.
{
  writeShellApplication,
  lib,
  uv,
  python313,
}:
let
  version = "18.1.8";
in
writeShellApplication {
  name = "keeper";
  runtimeInputs = [ uv ];
  text = ''
    export UV_PYTHON_DOWNLOADS=never
    exec uvx --python ${python313.interpreter} --from keepercommander==${version} keeper "$@"
  '';

  meta = {
    description = "Keeper Commander CLI, pinned keepercommander ${version} run via uvx";
    homepage = "https://github.com/Keeper-Security/Commander";
    license = lib.licenses.mit;
    mainProgram = "keeper";
  };
}
