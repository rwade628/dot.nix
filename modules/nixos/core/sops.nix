# sops-nix wiring. Each host's age identity is derived from its own SSH host
# key at activation time (sops.age.sshKeyPaths) - no separate age key file to
# generate or back up. See docs/adr/0006.
#
# Guarded by pathExists because not every NixOS host has been migrated off
# lib/secrets.nix yet (see modules/nixos/core/user.nix) - hosts without a
# secrets.yaml keep using the git-crypt-encrypted path until they are.
# nixos is intentionally never migrated (being deprecated - see #12).
{
  config,
  host,
  lib,
  ...
}:
let
  secretsFile = lib.custom.relativeToRoot "hosts/x86/${host.network.hostName}/secrets.yaml";
  commonSecretsFile = lib.custom.relativeToRoot "secrets/common.yaml";
in
lib.mkIf (builtins.pathExists secretsFile) {
  sops.defaultSopsFile = secretsFile;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # neededForUsers decrypts this before user accounts are created, since
  # hashedPasswordFile is consumed at that point in activation.
  sops.secrets.hashedPassword.neededForUsers = true;

  # Git identity secrets: the same value on every migrated host, so they live
  # in the Common secrets file rather than duplicated per-host (see
  # docs/adr/0006 and modules/home/core/ssh.nix / git.nix, which consume
  # these via the `hostConfig` home-manager extraSpecialArg).
  sops.secrets.gitSshPrivateKey = {
    sopsFile = commonSecretsFile;
    owner = host.user.name;
  };
  sops.secrets.gitFullName = {
    sopsFile = commonSecretsFile;
    owner = host.user.name;
  };
  sops.secrets.gitEmail = {
    sopsFile = commonSecretsFile;
    owner = host.user.name;
  };

  # git.nix includes this rendered file for [user] instead of baking
  # name/email into the Nix store via programs.git.settings.
  sops.templates.gitIdentity = {
    owner = host.user.name;
    content = ''
      [user]
        name = ${config.sops.placeholder.gitFullName}
        email = ${config.sops.placeholder.gitEmail}
    '';
  };
}
