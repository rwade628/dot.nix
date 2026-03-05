# Shared desktop configuration for all desktop environments
# Loads DE-specific configs which handle their own display managers
{
  config,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.optional (host.gnome or false) ./gnome)
    (lib.optional (host.niri or false) ./niri)
    (lib.optional (host.plasma or false) ./plasma)
  ];

  services = {
    # Enable user file access
    # gvfs.enable = true;
    # udisks2.enable = true;
    # Configure keyboard layout
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
      # Optionally customize rootless Docker daemon settings
      daemon.settings = {
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };
    };
  };

  # Fix for autoLogin - prevents getty from interfering
  # systemd.services."getty@tty1".enable = lib.mkIf host.autoLogin false;
  # systemd.services."autovt@tty1".enable = lib.mkIf host.autoLogin false;
}
