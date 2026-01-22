{
  pkgs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    # ./ananicy.nix
    ./gamemode.nix
    ./lutris.nix
    ./steam.nix
    ./sunshine.nix
  ];

  environment.systemPackages = with pkgs; [
    heroic
    vulkan-hdr-layer-kwin6
    umu-launcher
    quickemu
  ];

}
