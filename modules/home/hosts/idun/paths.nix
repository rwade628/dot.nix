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

  # Mirrors FLAKE above - modules/home/core/default.nix can't derive these from
  # sessionVariables.FLAKE itself (that creates an infinite recursion via nh's
  # own FLAKE compat shim), so each per-platform path is set independently.
  programs.nh.osFlake = "/Users/${host.user.osName}/git/dot.nix";
  programs.nh.homeFlake = "/Users/${host.user.osName}/git/dot.nix";
  programs.nh.darwinFlake = "/Users/${host.user.osName}/git/dot.nix";
}
