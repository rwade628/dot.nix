{
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "modules/home/gaming"
      "modules/home/utilities/xdg.nix"
      "modules/home/utilities/mullvad.nix"
      # "modules/home/shared/chromium.nix"
    ])

    ## NixOS Specific ##
    # ./config
  ];

  # Silence warning from old state version
  xdg.userDirs.setSessionVariables = true;
}
