{ pkgs, host, ... }:
{
  # GnuPG
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = if host.hasDesktop then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
  };
  services.pcscd.enable = true;
}
