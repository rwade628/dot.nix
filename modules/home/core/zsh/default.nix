{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    initContent = ''
      function ksn {
        kubectl config set-context --current --namespace $1 ;
      }
    '';

    shellAliases = {
      k = "kubectl";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      custom = "$HOME/.oh-my-zsh/custom/";
      plugins = [
        "git"
      ];
    };

    plugins = [
      {
        name = "zsh-fzf-history-search";
        src = pkgs.zsh-fzf-history-search;
        file = "share/zsh-fzf-history-search/zsh-fzf-history-search.zsh";
      }
    ];
  };

  home.packages = with pkgs; [
    eza
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
