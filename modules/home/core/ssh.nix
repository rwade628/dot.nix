{
  pkgs,
  config,
  lib,
  host,
  hostConfig,
  ...
}:
let
  ## The git/GitHub and server keys are sops-nix-only now: nothing in this
  ## module reads git-crypt-sourced key material anymore (see #12), so
  ## there's nothing to guard against clashing with the sops-managed
  ## ".ssh/git" / ".ssh/server" symlinks.
  hasSopsGitKey = hostConfig.sops.secrets ? gitSshPrivateKey;
  hasSopsServerKey = hostConfig.sops.secrets ? serverSshPrivateKey;
in
{
  home.file =
    lib.optionalAttrs (host.user.sshConfig != "") {
      ## SSH config file ##
      ".ssh/config_source" = {
        source = pkgs.writeText "ssh-config" host.user.sshConfig;
        onChange = ''
          cp $HOME/.ssh/config_source $HOME/.ssh/config
          chmod 400 $HOME/.ssh/config
        '';
      };
    }

    ## The git/GitHub and server keys are sops-nix-backed (see
    ## modules/nixos/core/sops.nix and modules/darwin/core/sops.nix):
    ## decrypted straight to a runtime-only path outside the Nix store, with
    ## permissions already set correctly by sops-nix, so they just need a
    ## symlink, not a store-path copy. mkOutOfStoreSymlink avoids Nix trying
    ## to import the (not-yet-decrypted-at-eval-time) target into the store.
    // lib.optionalAttrs hasSopsGitKey {
      ".ssh/git".source =
        config.lib.file.mkOutOfStoreSymlink hostConfig.sops.secrets.gitSshPrivateKey.path;
    }
    // lib.optionalAttrs hasSopsServerKey {
      ".ssh/server".source =
        config.lib.file.mkOutOfStoreSymlink hostConfig.sops.secrets.serverSshPrivateKey.path;
    };
}
