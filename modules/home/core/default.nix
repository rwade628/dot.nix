{
  config,
  lib,
  pkgs,
  host,
  ...
}:
let
  user = host.user;
  flakePath = "/home/${user.name}/git/dot.nix";
in
{
  imports = lib.flatten [
    (lib.custom.scanPaths ./.)

    # Desktop environment (if enabled)
    (lib.optional (host.niri or false) (lib.custom.relativeToRoot "modules/home/desktop/niri"))
    (lib.optional (host.plasma or false) (lib.custom.relativeToRoot "modules/home/desktop/plasma"))
  ];

  # services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault user.name;
    stateVersion = lib.mkDefault "25.05";
    sessionPath = [
      "/home/${host.user.name}/.local/bin"
      "/home/${host.user.name}/.local/npm"
      "/home/${host.user.name}/.krew/bin"
    ];
    sessionVariables = {
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
      FLAKE = lib.mkDefault flakePath;
      SHELL = lib.getExe user.shell;

      # homelab cluster credentials - kubectl/sops/talosctl read these natively,
      # so cluster access works from anywhere without cd-ing into the repo
      KUBECONFIG = "${config.home.homeDirectory}/git/homelab/kubeconfig";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/git/homelab/age.key";
      TALOSCONFIG = "${config.home.homeDirectory}/git/homelab/talos/clusterconfig/talosconfig";
    };
    # preferXdgDirectories = true; # whether to make programs use XDG directories whenever supported
  };

  programs.nix-index = {
    enable = true;
  };

  # Cross-platform nh config: nix-darwin has no system-level programs.nh module,
  # so this is the only place idun gets nh at all. The per-command *Flake vars
  # replace the plain `flake` field, which nh deprecates in favor of NH_FLAKE.
  #
  # Uses the flakePath literal directly rather than
  # config.home.sessionVariables.FLAKE: nh derives its legacy FLAKE env var
  # compat shim from these *Flake options, so reading it back out of
  # sessionVariables.FLAKE here closes an infinite-recursion loop.
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 10d --keep 10";
    osFlake = lib.mkDefault flakePath;
    homeFlake = lib.mkDefault flakePath;
    darwinFlake = lib.mkDefault flakePath;
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  programs.home-manager.enable = true;

  ## NIX NIX NIX ##
  # home.file =
  #   let
  #     nixConfig = pkgs.writeText "config.nix" ''
  #       {
  #         allowUnfree = true;
  #         fallback = true;
  #         connect-timeout = 10;
  #         permittedInsecurePackages = [
  #           "ventoy-gtk3-1.1.05"
  #           "modrinth-app"
  #           "mbedtls-2.28.10"
  #         ];
  #       }
  #     '';
  #   in
  #   {
  #     ".config/nixpkgs/config_source" = {
  #       source = nixConfig;
  #       onChange = ''
  #         cp $HOME/.config/nixpkgs/config_source $HOME/.config/nixpkgs/config.nix
  #         chmod 644 $HOME/.config/nixpkgs/config.nix
  #       '';
  #     };
  #   };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Catpuccin flavor and accent
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "lavender";
  };
}
