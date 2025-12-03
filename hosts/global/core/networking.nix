{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  # Check if any WireGuard service is enabled
  wireguardEnabled =
    (config.services.olm.enable or false)
    || (config.networking.wg-quick.interfaces != { })
    || (config.networking.wireguard.interfaces != { });
in
{
  # Essential WireGuard setup when any WireGuard-dependent service is enabled
  config = lib.mkMerge [
    # Base networking configuration
    {
      networking = {
        dhcpcd.enable = false;
        hostName = host.network.hostName;
        useDHCP = false; # Disable the old DHCP system
        networkmanager.enable = false;
        useNetworkd = true;
        # useHostResolvConf = false;
        # usePredictableInterfaceNames = true;
      };
    }

    # WireGuard configuration when needed
    (lib.mkIf wireguardEnabled {
      # Ensure WireGuard kernel module is available
      boot.kernelModules = [ "wireguard" ];

      # Include WireGuard tools in system packages
      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];

      # Enable IP forwarding if this is a server/router
      # (only for hosts that route traffic between interfaces)
      boot.kernel.sysctl = lib.mkIf (config.currentHost.isServer or false) {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    })
  ];
}
