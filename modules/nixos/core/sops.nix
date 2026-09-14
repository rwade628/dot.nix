# sops-nix wiring. Each host's age identity is derived from its own SSH host
# key at activation time (sops.age.sshKeyPaths) - no separate age key file to
# generate or back up. See docs/adr/0006.
#
# Guarded by pathExists because not every NixOS host has been migrated off
# lib/secrets.nix yet (see modules/nixos/core/user.nix) - hosts without a
# secrets.yaml keep using the git-crypt-encrypted path until they are.
{
  host,
  lib,
  ...
}:
let
  secretsFile = lib.custom.relativeToRoot "hosts/x86/${host.network.hostName}/secrets.yaml";
in
lib.mkIf (builtins.pathExists secretsFile) {
  sops.defaultSopsFile = secretsFile;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # neededForUsers decrypts this before user accounts are created, since
  # hashedPasswordFile is consumed at that point in activation.
  sops.secrets.hashedPassword.neededForUsers = true;
}
