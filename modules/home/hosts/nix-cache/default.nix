{
  lib,
  pkgs,
  ...
}:
{
  # Silence warning from old state version
  xdg.userDirs.setSessionVariables = true;
}
