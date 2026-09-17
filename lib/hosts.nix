# Constants data implementation (host configuration)
# Non-sensitive configuration values for hosts
{
  ...
}:
let
  # Public key authorized to log in as `ryan` on every host - not sensitive,
  # so it lives here as a plain value rather than as a sops-nix secret
  # (openssh.authorizedKeys.keys needs a Nix-eval-time value, which sops-nix
  # secrets can't provide). Paired private key is the sops-nix-managed
  # `serverSshPrivateKey` secret in secrets/common.yaml.
  ryanSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/G59cekOy/Yw2v6+hJcG7gDYY4bPUblCAt/whZixW7 ryan"
  ];

  # SSH client config - not sensitive (no secrets, just IdentityFile paths
  # and connection settings), and identical for every host, so it lives
  # here as a plain value rather than as a secret.
  ryanSshConfig = ''
    Host github.com
      IdentityFile "~/.ssh/git"

    Host *
      ForwardAgent no
      AddKeysToAgent yes
      Compression no
      ServerAliveInterval 5
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no

      IdentityFile "~/.ssh/server"
      UpdateHostKeys ask
  '';
in
{
  # No need to import spec here - it's imported in evalModules

  hostSpec = {
    ## X86 Hosts ##
    loki = {
      network = {
        hostName = "loki";
      };
      user = {
        name = "ryan";
        sshAuthorizedKeys = ryanSshAuthorizedKeys;
        sshConfig = ryanSshConfig;
      };
      mounts = {
        media = true;
      };
      isServer = true;
      # Explicit (matches the default) so it's clear loki needs the full
      # modules/home/users/ryan profile — modules/home/hosts/loki carries
      # kubectl, krew, ffmpeg, and its networking/monitoring tools.
      isMinimal = false;
    };

    ## Darwin Hosts ##
    idun = {
      network = {
        hostName = "idun";
      };
      user = {
        name = "ryan";
        sshAuthorizedKeys = ryanSshAuthorizedKeys;
        sshConfig = ryanSshConfig;
        # Pre-existing macOS account; nix-darwin can't create accounts, so this
        # must match the account already on the machine. Config and the
        # shared home-manager module still key off `name` ("ryan") above.
        osName = "rdubs628";
      };
      hasDesktop = true;
    };
  };
}
