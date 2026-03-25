{ pkgs, ... }:
{
  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };
  environment.systemPackages = with pkgs; [
    gamescope-wsi # HDR won't work without this
  ];
}
