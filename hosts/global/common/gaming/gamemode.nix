{
  pkgs,
  ...
}:
{
  programs.gamemode = {
    enable = true;
    # enableRenice = true;
    settings = {
      # general = {
      #   softrealtime = "auto";
      #   inhibit_screensaver = 1;
      #   renice = 15;
      # };
      # gpu = {
      #   apply_gpu_optimisations = "accept-responsibility";
      #   gpu_device = 1;
      #   # amd_performance_level = "high";
      # };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };
}
