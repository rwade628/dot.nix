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
      editor.fzf.enable = true;
      editor.snacks_explorer.enable = true;
      editor.snacks_picker.enable = true;
      lang.docker.enable = true;
      lang.git.enable = true;
      lang.go.enable = true;
      lang.json.enable = true;
      lang.markdown.enable = true;
      lang.nix.enable = true;
      lang.terraform.enable = true;
      lang.toml.enable = true;
      lang.typescript.enable = true;
      lang.yaml.enable = true;
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
      mermaid-cli

      # Other tools
      ast-grep
      sqlite

      # Build tools
      gcc
      tree-sitter
      cargo

      # luarocks for lazy.nvim rocks health check
      luarocks
    ];
  };
}
