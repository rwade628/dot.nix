# nix-darwin doesn't create accounts - idun's primary user must already exist
# on the Mac (created via macOS Setup Assistant). This only overrides
# shell/uid/ssh-authorized-keys on that existing account.
{
  inputs,
  host,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user;
  userSecrets = secrets.users.${user.name} or { };
in
{
  system.primaryUser = user.name;

  users.users.${user.name} = {
    home = "/Users/${user.name}";
    shell = user.shell or pkgs.zsh;
    uid = lib.mkIf (user.uid != null) user.uid;
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };
}
// lib.optionalAttrs (inputs ? "home-manager") {
  # Set up home-manager for the configured user
  home-manager = {
    extraSpecialArgs = {
      inherit
        pkgs
        inputs
        host
        secrets
        ;
      # Don't pass lib - let home-manager use its own extended lib with hm namespace
    };
    users = {
      ${user.name} = {
        imports = [
          inputs.catppuccin.homeModules.catppuccin
          (
            { config, ... }:
            import (lib.custom.relativeToRoot "modules/home/users/${user.name}") {
              inherit
                config
                host
                inputs
                lib
                pkgs
                secrets
                ;
            }
          )
        ];
      };
    };
  };
}
