{
  lib,
  config,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/lazyvim";

  home.file.".steam/steam/steam_dev.cfg".text = ''
    @nClientDownloadEnableHTTP2PlatformLinux 0
    unShaderBackgroundProcessingThreads 16
  '';

}
