{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  programs.lazyvim = {
    enable = true;
    # Core LazyVim dependencies (git, ripgrep, fd, etc.)
    installCoreDependencies = true; # default: true

    configFiles = ./lazyvim;

    extras = {
      coding.yanky = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      editor.fzf = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      editor.snacks_explorer = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.docker = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.git = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.go = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.json = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.markdown = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.nix = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.terraform = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.toml = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.typescript = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      lang.yaml = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
      util.dot = {
        enable = true;
        # installDependencies = true;
        # installRuntimeDependencies = true;
      };
    };
  };

  programs.neovim.extraPackages = with pkgs; [
    # Nix development tools
    nixd
    nil
    statix
    nixpkgs-fmt
    nixfmt
    editorconfig-checker
    shellcheck

    # Language servers and tools
    vscode-langservers-extracted
    yaml-language-server
    marksman
    markdownlint-cli2
    stylua
    shfmt

    # Build tools
    gcc
    tree-sitter
    cargo

    # General utilities
    ripgrep
    fd
    fzf
    lazygit
    unzip
    wget
  ];
}
