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
        "zsh-fzf-history-search"
      ];
    };
  };

  home.packages = with pkgs; [
    eza
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
