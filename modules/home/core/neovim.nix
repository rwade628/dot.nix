{
  pkgs,
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
      nixfmt-rfc-style
    ];
  };
}
