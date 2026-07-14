# Core system settings shared by all hosts
{
  pkgs,
  ...
}:

{
  # --- Core Settings ---
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- System Compatibility ---
  programs.nix-ld = {
    enable = true; # Run non-nix executables (e.g., micromamba)
    # Provide the missing shared libraries specifically required by Chrome
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libgbm
      libdrm
      libxkbcommon
      nspr
      nss
      pango
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
    ];
  };

  boot.kernelModules = [ "tcp_bbr" ];

  # Don't prompt for ZFS encryption keys at boot
  # Our root datasets are unencrypted; only replicated backup datasets from TrueNAS are encrypted
  # Without this, replicated encrypted datasets block boot waiting for a passphrase
  boot.zfs.requestEncryptionCredentials = false;

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1; # Enable Magic SysRq key for recovery

    # BBR congestion control - doesn't back off aggressively on loss like CUBIC
    "net.ipv4.tcp_congestion_control" = "bbr";

    # TCP buffer tuning for high-latency, high-bandwidth connections
    # Default 208KB is too small for transatlantic links (BDP at 300Mbps/263ms = 10MB)
    "net.core.rmem_max" = 134217728; # 128MB
    "net.core.wmem_max" = 134217728; # 128MB
    "net.ipv4.tcp_rmem" = "4096 131072 134217728"; # min default max
    "net.ipv4.tcp_wmem" = "4096 16384 134217728"; # min default max
  };

  # --- Shell & Terminal ---
  programs.zsh.enable = true;
  programs.direnv.enable = true;
}
