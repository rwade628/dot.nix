{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Neovim with LazyVIM
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      gcc # needed for nvim-treesitter
      tree-sitter
      cargo

      # HTML, CSS, JSON
      vscode-langservers-extracted

      # LazyVim defaults
      stylua
      shfmt

      # Markdown extra
      markdownlint-cli2
      marksman

      # JSON and YAML extras
      yaml-language-server

      # Custom
      editorconfig-checker
      shellcheck
      nixd
      nil
      statix
      nixpkgs-fmt
      nixfmt

      # Additional LazyVim dependencies
      ripgrep
      fd
      fzf
      lazygit
      unzip
      wget
    ];
  };

  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink /home/ryan/git/dot.nix/nvim;
}
