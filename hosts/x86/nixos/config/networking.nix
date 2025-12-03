{
  systemd.network.networks."10-enp42s0" = {
    matchConfig.Name = "enp42s0";
    networkConfig = {
      DHCP = "ipv4";
      VLAN = "enp42s0.50";
    };
    dhcpV4Config.RouteMetric = 100;
  };

  systemd.network.netdevs."enp42s0.50" = {
    netdevConfig = {
      Kind = "vlan";
      Name = "enp42s0.50"; # The name of the new sub-interface
    };
    vlanConfig = {
      Id = 50;
    };
  };

  systemd.network.networks."50-enp42s0.50" = {
    matchConfig.Name = "enp42s0.50";
    networkConfig = {
      DHCP = "ipv4";

      # The LinkLocalAddressing option is often helpful to prevent autoconfiguration
      LinkLocalAddressing = "no";
    };
    dhcpV4Config.RouteMetric = 200;
  };
}
