{
  # Replaces the default terminal emulator;
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # theme = "stylix";
      font-family = "monospace";
      font-size = "11";
      background-opacity = "0.85";
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
