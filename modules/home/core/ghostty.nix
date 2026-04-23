{
  # Replaces the default terminal emulator;
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    # enableFishIntegration = true;
    settings = {
      theme = "Catppuccin Mocha";
      command = "tmux has-session -t 0 2>/dev/null && tmux attach || tmux new-session -d -s 0 && tmux attach";
      font-family = "monospace";
      font-size = "11";
      background-opacity = "0.85";
      background-opacity-cells = true;
      keybind = ''shift+enter=text:\x1b\r'';
      window-height = 45;
      window-width = 145;
      window-inherit-working-directory = true;
      # async-backend = "epoll";
    };
  };

  home.sessionVariables = {
    TERM = "ghostty";
  };
}
