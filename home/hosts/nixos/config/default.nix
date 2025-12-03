{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  monitors = [
    {
      name = "DP-1";
      primary = true;
      width = 3840;
      height = 2160;
      refreshRate = 240.02;
      x = 2195;
      y = 0;
      scale = 1.5;
      transform = 0;
      enabled = true;
      hdr = true;
      vrr = true;
    }
    {
      name = "HDMI-A-1";
      primary = false;
      width = 3840;
      height = 2160;
      refreshRate = 119.88;
      x = 0;
      y = 99;
      scale = 1.75;
      transform = 0;
      enabled = true;
      hdr = true;
      vrr = true;
    }
  ];

  home.file.".config/monitors_source" = {
    source = ./monitors.xml;
    onChange = ''
      cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
      chmod 755 $HOME/.config/monitors.xml
    '';
  };
}
