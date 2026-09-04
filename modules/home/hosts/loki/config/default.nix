{
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
    ])
  ];

  # Silence warning from old state version
  xdg.userDirs.setSessionVariables = true;
}
