# User config applicable only to nixos
{
  config,
  host,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user;
  # Get user-specific secrets if they exist
  userSecrets = secrets.users.${user.name} or { };
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  isMinimal = host.isMinimal;
  # Migrated hosts (see modules/nixos/core/sops.nix) get the password from
  # sops-nix; hosts not yet migrated keep the git-crypt-encrypted value.
  hashedPasswordFile = config.sops.secrets.hashedPassword.path or null;
in
{
  users.mutableUsers = false;
  users.users.${user.name} = {
    isNormalUser = true;
    createHome = true;
    description = "Admin";
    homeMode = "750";
    hashedPasswordFile = hashedPasswordFile;
    hashedPassword = lib.mkIf (hashedPasswordFile == null) userSecrets.hashedPassword;
    uid = 1000;
    shell = user.shell or pkgs.zsh;
    extraGroups = lib.flatten [
      "wheel"
      (ifTheyExist [
        "adbusers"
        "audio"
        "docker"
        "gamemode"
        "git"
        "libvirtd"
        "networkmanager"
        "video"
        "i2c"
        "input"
      ])
    ];
    openssh.authorizedKeys.keys = userSecrets.ssh.publicKeys or [ ];
  };

  # Special sudo config for user
  security.sudo.extraRules = [
    {
      users = [ user.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  programs.git.enable = true;

  users.users.root = {
    shell = pkgs.bash;
    hashedPasswordFile = lib.mkForce hashedPasswordFile;
    # Forced (not mkIf) because virtualisation/lxc-instance-common.nix sets
    # root.initialHashedPassword = "" at mkOverride 150, which otherwise
    # trips NixOS's "multiple password options set" warning even though
    # hashedPasswordFile already wins on priority.
    hashedPassword = lib.mkForce (if hashedPasswordFile == null then userSecrets.hashedPassword else null);
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
      # hostConfig gives shared home-manager modules (e.g. ssh.nix, git.nix)
      # read access to system-level config, namely `sops.secrets`/`sops.templates`
      # paths - normalized so those modules don't need to branch on platform
      # (NixOS's own home-manager module would expose this as `osConfig`,
      # Darwin's as `darwinConfig`; we inject one consistent name instead).
      hostConfig = config;
      # Don't pass lib - let home-manager use its own extended lib with hm namespace
    };
    users = {
      root.home.stateVersion = "25.11";
      ${user.name} = {
        imports = [
          inputs.catppuccin.homeModules.catppuccin
          (
            { config, ... }:
            import
              (
                if isMinimal then
                  lib.custom.relativeToRoot "modules/home/core"
                else
                  lib.custom.relativeToRoot "modules/home/users/${user.name}"
              )
              {
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
