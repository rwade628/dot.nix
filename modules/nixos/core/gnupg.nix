{ pkgs, ... }:
{
  # GnuPG
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    # cacheTtl = 8 * 60 * 60;
    # defaultCacheTtl = 8 * 60 * 60;
  };
  services.pcscd.enable = true;
}
