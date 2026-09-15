# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  lib,
  config,
  inputs,
  host,
  hostConfig,
  secrets,
  ...
}:
let
  user = host.user;
  userSecrets = secrets.users.${user.name};
  # sops-nix migrated hosts render [user] name/email at activation time into
  # a runtime file (see modules/nixos/core/sops.nix / modules/darwin/core/sops.nix)
  # and it's pulled in below via `includes`, instead of being set here - that
  # would bake the values into the Nix store via the generated ~/.gitconfig,
  # exactly what this migration is meant to avoid. Hosts not yet migrated
  # (nixos) fall back to the git-crypt-sourced value.
  hasSopsIdentity = hostConfig.sops.templates ? gitIdentity;
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    ignores = [
      ".csvignore"
      # nix
      "*.drv"
      "result"
      # python
      "*.py?"
      "__pycache__/"
      ".venv/"
      # direnv
      ".direnv"
    ];

    includes = lib.optional hasSopsIdentity { path = hostConfig.sops.templates.gitIdentity.path; };

    # Anytime I use auth, I want to use my yubikey. But I don't want to always be having to touch it
    # for things that don't need it. So I have to hardcode repos that require auth, and default to ssh for
    # actions that require auth.
    settings = {
      user = lib.optionalAttrs (!hasSopsIdentity) {
        name = userSecrets.fullName;
        email = userSecrets.email;
      };

      core = {
        pager = "delta";
        # pre-emptively ignore mac crap
        excludeFiles = builtins.toFile "global-gitignore" ''
          .DS_Store
          .DS_Store?
          ._*
          .Spotlight-V100
          .Trashes
          ehthumbs.db
          Thumbs.db
          node_modules
        '';
        attributesfile = builtins.toFile "global-gitattributes" ''
          Cargo.lock -diff
          flake.lock -diff
          *.drawio -diff
          *.svg -diff
          *.json diff=json
          *.bin diff=hex difftool=hex
          *.dat diff=hex difftool=hex
          *aarch64.bin diff=objdump-aarch64 difftool=objdump-aarch64
          *arm.bin diff=objdump-arm difftool=objdump-arm
          *x64.bin diff=objdump-x86_64 difftool=objdump-x64
          *x86.bin diff=objdump-x86 difftool=objdump-x86
        '';
      };

      delta = {
        enable = true;
        features = [
          "side-by-side"
          "line-numbers"
          "hyperlinks"
          "line-numbers"
          "commit-decoration"
        ];
      };

      url = lib.optionalAttrs (!host.isMinimal) {
        # Only force ssh if it's not minimal
        "ssh://git@github.com" = {
          pushInsteadOf = "https://github.com";
        };
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

}
