{ pkgs, ... }:
{
  # services.keyd = {
  #   enable = true;
  #   keyboards = {
  #     default = {
  #       ids = [ "*" ];
  #       settings = {
  #         # The binding MUST be inside 'main'
  #         main = {
  #           "leftmeta+leftshift+m" =
  #             "command(${pkgs.su}/bin/su ryan -c 'WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-1.enable output.HDMI-A-1.disable')";
  #           "leftmeta+leftshift+t" =
  #             "command(${pkgs.su}/bin/su ryan -c 'WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-1.disable output.HDMI-A-1.enable')";
  #         };
  #       };
  #     };
  #   };
  services.triggerhappy = {
    enable = true;
    bindings = [
      {
        keys = [
          "M"
          "LEFTSHIFT"
          "LEFTMETA"
        ];
        cmd = "${pkgs.su}/bin/su ryan -c 'WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-1.enable output.HDMI-A-1.disable'";
      }
      {
        keys = [
          "T"
          "LEFTSHIFT"
          "LEFTMETA"
        ];
        cmd = "${pkgs.su}/bin/su ryan -c 'WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-1.disable output.HDMI-A-1.enable'";
      }
    ];
  }; # };
}
