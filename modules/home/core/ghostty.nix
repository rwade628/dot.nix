{
  # Replaces the default terminal emulator;
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    # enableFishIntegration = true;
    settings = {
      theme = "Catppuccin Mocha";
    
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
