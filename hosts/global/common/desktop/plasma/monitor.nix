# modules/services/hass-display-switcher-hybrid.nix
{
  pkgs,
  secrets,
  host,
  ...
}:

let
  hassURL = "https://hass.casadewade.com";
  hassToken = secrets.users.${host.user.name}.hassToken;
  desktopUser = host.user.name;

  # Define the required Home Assistant CLI command
  hass-check-command = ''
    ${pkgs.home-assistant-cli}/bin/hass-cli \
      --no-headers \
      --columns=STATE="state" \
      -o json \
      state list media_player.samsung \
      | ${pkgs.jq}/bin/jq -r '.[0].state'
  '';

  # Define the core logic script
  display-switcher-script = pkgs.writeShellScript "display-switcher" ''
    # Environment variables
    export HASS_SERVER="${hassURL}"
    export HASS_TOKEN="${hassToken}"
    export HOME="/home/${desktopUser}"

    # Define outputs
    export TV_OUTPUT="HDMI-A-1"
    export DP_OUTPUT="DP-1"

    # --- NETWORK WAIT LOOP ---
    # We cannot check HA without network. 
    # Try for 10 seconds to reach Local DNS before giving up or proceeding.
    for i in {1..10}; do
      if ${pkgs.iputils}/bin/ping -c 1 -W 1 192.168.88.1 > /dev/null 2>&1; then
        echo "$(date) Network is up."
        break
      fi
      echo "$(date) Waiting for network..."
      sleep 1
    done

    # 1. Get current TV state from Home Assistant
    # We capture stderr to prevent the script from crashing if HA is unreachable
    TV_STATE=$(${hass-check-command} 2>/dev/null)

    if [ -z "$TV_STATE" ]; then
       echo "$(date) Failed to retrieve HA state. Aborting switch."
       exit 0
    fi

    if [ "$TV_STATE" = "on" ] || [ "$TV_STATE" = "playing" ]; then
      echo "$(date) [WAYLAND] TV is ON/Playing ($TV_STATE). Switching to $TV_OUTPUT."
      ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
        output.$TV_OUTPUT.enable \
        output.$DP_OUTPUT.disable
    else
      echo "$(date) [WAYLAND] TV is OFF ($TV_STATE). Switching to $DP_OUTPUT."
      ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
        output.$DP_OUTPUT.enable \
        output.$TV_OUTPUT.disable
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [
    home-assistant-cli
    jq
    iputils
  ];

  # 1. THE USER SERVICE (Does the work)
  # This has native access to the DBus session and Wayland socket.
  systemd.user.services.hass-display-switcher = {
    unitConfig = {
      Description = "Dynamic Display Switching (User Context)";
      # # Ensure it doesn't try to run multiple instances if wake triggers rapidly
      # ConditionPathExists = "/run/user/1000/bus";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${display-switcher-script}";
    };
  };

  # 2. THE SYSTEM SERVICE (The Trigger)
  # This watches for system-level wake events.
  systemd.services.hass-display-trigger = {
    description = "Trigger User Display Switcher on Wake";
    # Run AFTER the suspend target is reached (i.e., on Resume)
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    # "WantedBy" replaces the [Install] section
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      # This command tells the system to reach into your user session and start the service
      ExecStart = "${pkgs.systemd}/bin/systemctl --machine=${desktopUser}@.host --user start hass-display-switcher.service";
    };
  };
}
