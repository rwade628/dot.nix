{
  config,
  lib,
  pkgs,
  host,
  ...
}:
let
  user = host.user;
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
      FLAKE = lib.mkDefault "/home/${host.user.name}/git/dot.nix";
      SHELL = lib.getExe user.shell;
    };
    # preferXdgDirectories = true; # whether to make programs use XDG directories whenever supported
  };

  programs.nix-index = {
    enable = true;
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
