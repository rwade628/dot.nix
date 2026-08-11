# modules/home/core/default.nix hardcodes /home/<user> paths (Linux convention).
# macOS home directories live at /Users/<user>, so idun overrides them here.
{ host, lib, ... }:
{
  home.homeDirectory = lib.mkForce "/Users/${host.user.name}";
  home.sessionPath = lib.mkForce [
    "/Users/${host.user.name}/.local/bin"
    "/Users/${host.user.name}/.local/npm"
    "/Users/${host.user.name}/.krew/bin"
  ];
  home.sessionVariables.FLAKE = "/Users/${host.user.name}/git/dot.nix";
}
