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

    configFiles = ./lazyvim;

    extras = {
      coding.yanky.enable = true;
      editor = {
        fzf.enable = true;
        snacks-explorer.enable = true;
        snacks-picker.enable = true;
      };
      lang = {
        docker.enable = true;
        git.enable = true;
        go.enable = true;
        json.enable = true;
        markdown.enable = true;
        nix.enable = true;
        terraform.enable = true;
        toml.enable = true;
        typescript.enable = true;
        yaml.enable = true;
      };
      util.dot.enable = true;
    };

    # Fish parser needed because util.dot extra auto-detects ~/.config/fish
    # and adds fish to treesitter ensure_installed
    # Additional parsers for snacks.image TS language support
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      fish
      css
      latex
      scss
      svelte
      typst
      vue
    ];

    extraPackages = with pkgs; [
      # Nix development tools
      nixd
      nil
      statix
      alejandra
      editorconfig-checker

      # Language servers
      bash-language-server
      docker-compose-language-service
      dockerfile-language-server
      gopls
      lua-language-server
      taplo
      terraform-ls
      vtsls

      # Language servers (already present)
      vscode-langservers-extracted
      yaml-language-server
      marksman

      # Formatters
      gofumpt
      gotools
      markdownlint-cli2
      prettier
      stylua
      shfmt

      # Markdown TOC
      markdown-toc

      # Image rendering tools (snacks.image)
      imagemagick
      ghostscript
      tectonic

      # Other tools
      ast-grep
      sqlite

      # Build tools
      gcc
      tree-sitter

      # luarocks for lazy.nvim rocks health check
      luarocks
    ];
  };
}
