# Steam module with gaming optimizations
{
  pkgs,
  inputs,
  ...
}:
{

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;

    protontricks = {
      enable = true;
      package = pkgs.protontricks;
    };

    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          # X11 libraries
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver

          # System libraries
          stdenv.cc.cc.lib
          gamemode
          gperftools
          keyutils
          libkrb5
          libpng
          libpulseaudio
          libvorbis
          mangohud
        ];
      extraEnv = {
        TZ = "EST5EDT";
        # TZ = "America/New_York";
        TZDIR = "/usr/share/zoneinfo";
      };
      extraProfile = ''
        unset TZ
      '';
    };
  };
}
