# Steam module with gaming optimizations
{
  pkgs,
  inputs,
  ...
}:

let
  proton-cachyos = inputs.chaotic.legacyPackages.${pkgs.system}.proton-cachyos;
  proton-ge-custom = inputs.chaotic.legacyPackages.${pkgs.system}.proton-ge-custom;
in
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
    };

    # Use the combined list of default + user extras
    extraCompatPackages = with pkgs; [
      proton-cachyos
      proton-ge-custom
      proton-ge-bin
    ];
  };
}
