{
  pkgs,
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;
}
