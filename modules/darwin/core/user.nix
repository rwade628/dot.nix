# nix-darwin doesn't create accounts - idun's primary user must already exist
# on the Mac (created via macOS Setup Assistant). This only overrides
# shell/uid/ssh-authorized-keys on that existing account.
{
  config,
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
  system.primaryUser = user.osName;

  users.users.${user.osName} = {
    home = "/Users/${user.osName}";
    shell = user.shell or pkgs.zsh;
    uid = lib.mkIf (user.uid != null) user.uid;
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };
}
// lib.optionalAttrs (inputs ? "home-manager") {
  # Set up home-manager for the configured user. The attr name must match the
  # OS account (user.osName); the imported module content still keys off
  # user.name ("ryan") for secrets and the shared modules/home/users/ module.
  home-manager = {
    extraSpecialArgs = {
      inherit
        pkgs
        inputs
        host
        secrets
        ;
      # hostConfig gives shared home-manager modules (e.g. ssh.nix, git.nix)
      # read access to system-level config, namely `sops.secrets`/`sops.templates`
      # paths - normalized so those modules don't need to branch on platform
      # (NixOS's own home-manager module would expose this as `osConfig`,
      # Darwin's as `darwinConfig`; we inject one consistent name instead).
      hostConfig = config;
      # Don't pass lib - let home-manager use its own extended lib with hm namespace
    };
    users = {
      ${user.osName} = {
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
