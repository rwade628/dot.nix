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

    # SHARE_HISTORY appends with timestamps regardless; without this, full
    # rewrites (exit, trim) strip them, leaving a mixed-format file.
    history.extended = true;

    initContent = ''
      function ksn {
        kubectl config set-context --current --namespace $1 ;
      }

      source ${./session-history.zsh}
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
