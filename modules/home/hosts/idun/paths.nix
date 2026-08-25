# modules/home/core/default.nix hardcodes /home/<user> paths (Linux convention)
# and defaults home.username to host.user.name. macOS home directories live at
# /Users/<osName> under the pre-existing account name, so idun overrides them here.
{ host, lib, ... }:
{
  home.username = lib.mkForce host.user.osName;
  home.homeDirectory = lib.mkForce "/Users/${host.user.osName}";
  home.sessionPath = lib.mkForce [
    "/Users/${host.user.osName}/.local/bin"
    "/Users/${host.user.osName}/.local/npm"
    "/Users/${host.user.osName}/.krew/bin"
  ];
  home.sessionVariables.FLAKE = "/Users/${host.user.osName}/git/dot.nix";
}
