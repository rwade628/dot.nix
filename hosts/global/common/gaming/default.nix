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
  ];

  environment.systemPackages = with pkgs; [
    heroic
  ];

}
