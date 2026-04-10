{
  lib,
  config,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.file.".steam/steam/steam_dev.cfg".text = ''
    @nClientDownloadEnableHTTP2PlatformLinux 0
    unShaderBackgroundProcessingThreads 16
  '';

}
