{
  config,
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    enableHidpi = true;
    settings.Theme.CursorTheme = "Yaru";
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wev # Wayland event viewer for debugging keybindings
    grim # Screenshot utility
    slurp # Screen area selection tool
    wf-recorder # Screen recording
    wl-color-picker # Color picker for Wayland
    libnotify
    cliphist

    # Utility
    # gnome-disk-utility
    qdirstat
    inxi
    util-linux

    # Media control
    playerctl
    pavucontrol
    wireplumber

    # Network/Bluetooth manager
    networkmanagerapplet

    # Applications
    eloquent # Spell checker
    glib
    gnumake
    mesa
    swayidle
  ];

  programs.firefox.enable = true;
  programs.xwayland.enable = true;

  # Enable pipewire for audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Enable brightness control via DDC/CI (for external monitors)
  # This allows the brightness script to work
  hardware.i2c.enable = true;

  # Grant access to i2c devices for DDC control
  services.udev.extraRules = ''
    # Allow users in video group to access i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"
  '';

  # Ensure user is in video group for DDC access
  users.users.${host.user.name}.extraGroups = [ "video" ];

  # Enable XDG desktop portal for kde
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk # Fallback for GTK apps
    ];
    # Explicitly set KDE as the default portal implementation
    config = {
      common = {
        default = [
          "kde"
          "gtk"
        ];
        # Force these specific interfaces to use KDE to stop the GTK fallback
        "org.freedesktop.impl.portal.ScreenCast" = [ "kde" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "kde" ];
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      };
      # Ensure that when in a Plasma session, KDE is the only choice
      plasma = {
        default = [ "kde" ];
      };
    };
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # For Electron apps
    XCURSOR_SIZE = "24"; # Cursor size
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland
    XDG_CURRENT_DESKTOP = "KDE"; # Ensure KDE is recognized
    XDG_SESSION_DESKTOP = "KDE";
    # Force Qt apps to use the wayland-kde portal
    QT_QPA_PLATFORM = "wayland;xcb";
    GTK_USE_PORTAL = "1";
  };

  # Enable location services for night light
  services.geoclue2.enable = true;

  services.flatpak.enable = true;

  # Font configuration for better rendering
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    subpixel.rgba = "rgb";
  };
}
