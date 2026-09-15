{
  pkgs,
  config,
  lib,
  host,
  hostConfig,
  secrets,
  ...
}:
let
  ## Get the current user's SSH config ##
  userSsh = secrets.users.${host.user.name}.ssh or { };

  ## The git/GitHub key is sops-nix-only now (see below) - lib/secrets.nix
  ## has no git-crypt-sourced fallback for it, so there's nothing here to
  ## guard against clashing with the sops-managed ".ssh/git" symlink.
  hasSopsGitKey = hostConfig.sops.secrets ? gitSshPrivateKey;

  ## SSH key creation function ##
  mkSshKeyFile =
    name: content:
    pkgs.writeTextFile {
      name = "ssh-key-${name}";
      text = content;
      executable = false;
      checkPhase = ''
        grep -q "BEGIN OPENSSH PRIVATE KEY" "$out" || (echo "Invalid SSH key format"; exit 1)
      '';
    };

  ## Create private key files from privateKeyContents ##
  privateKeys = lib.mapAttrs (name: content: mkSshKeyFile "${host.user.name}-${name}" content) (
    userSsh.privateKeyContents or { }
  );

  ## Generate local key paths for the config ##
  sshKeysMap = lib.mapAttrs (name: _: "~/.ssh/${name}") privateKeys;
in
{
  home.file =
    lib.optionalAttrs (userSsh ? config) {
      ## SSH config file ##
      ".ssh/config_source" = {
        source = userSsh.config;
        onChange = ''
          cp $HOME/.ssh/config_source $HOME/.ssh/config
          chmod 400 $HOME/.ssh/config
        '';
      };
    }
    // lib.optionalAttrs ((userSsh.knownHosts or [ ]) != [ ]) {
      ## Known hosts ##
      ".ssh/known_hosts_source" = {
        source = pkgs.writeText "known-hosts" (lib.concatStringsSep "\n" (userSsh.knownHosts or [ ]));
        onChange = ''
          cp $HOME/.ssh/known_hosts_source $HOME/.ssh/known_hosts
          chmod 644 $HOME/.ssh/known_hosts
        '';
      };
    }

    ## Dynamically copy all SSH private keys from store ensuring symlinks are not used ##
    // lib.mapAttrs' (name: path: {
      name = ".ssh/${name}_source";
      value = {
        source = path;
        onChange = ''
          cp $HOME/.ssh/${name}_source $HOME/.ssh/${name}
          chmod 600 $HOME/.ssh/${name}
        '';
      };
    }) privateKeys

    ## The git/GitHub key is sops-nix-backed (see modules/nixos/core/sops.nix
    ## and modules/darwin/core/sops.nix): decrypted straight to a runtime-only
    ## path outside the Nix store, with permissions already set correctly by
    ## sops-nix, so - unlike the keys above - it just needs a symlink, not a
    ## store-path copy. mkOutOfStoreSymlink avoids Nix trying to import the
    ## (not-yet-decrypted-at-eval-time) target into the store.
    // lib.optionalAttrs hasSopsGitKey {
      ".ssh/git".source = config.lib.file.mkOutOfStoreSymlink hostConfig.sops.secrets.gitSshPrivateKey.path;
    };
}
