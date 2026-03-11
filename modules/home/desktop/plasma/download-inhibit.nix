{ pkgs, config, ... }:

let
  downloadDir = "/mnt/data/libre";

  # The Checker Script
  # It checks for temp files. If found, it "holds" the system for 65 seconds.
  checkScript = pkgs.writeShellScript "check-downloads" ''
    # Check for common browser temporary files
    if ${pkgs.findutils}/bin/find "${downloadDir}" -maxdepth 1 -name "*.part" -o -name "*.crdownload" -o -name "*.tmp" | ${pkgs.gnugrep}/bin/grep -q .; then
      echo "Active download detected. Inhibiting sleep for 65 seconds..."
      # This blocks sleep/idle. We run it for 65s so it overlaps with the 60s timer
      ${pkgs.systemd}/bin/systemd-inhibit \
        --who="Download Watcher" \
        --why="File in Downloads still has temporary extension" \
        --mode=block \
        --what=sleep \
        ${pkgs.coreutils}/bin/sleep 65
    else
      exit 0
    fi
  '';
in
{
  # 1. The Service (What to do)
  systemd.user.services.download-inhibit-check = {
    Unit = {
      Description = "Check for active downloads and inhibit sleep";
    };
    Service = {
      Type = "simple";
      ExecStart = "${checkScript}";
      # Ensure the directory exists to avoid script errors
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${downloadDir}";
    };
  };

  # 2. The Timer (When to do it)
  systemd.user.timers.download-inhibit-check = {
    Unit = {
      Description = "Run download inhibit check every minute";
    };
    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m"; # Check every minute
      AccuracySec = "10s"; # Allows systemd to group tasks to save battery
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
