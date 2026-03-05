{ ... }:
{
  networking = {
    interfaces = {
      enp42s0 = {
        wakeOnLan.enable = true;
      };
    };
    firewall = {
      allowedUDPPorts = [ 9 ];
    };
    # nameservers = [
    #   "10.0.10.1"
    #   "100.100.100.100"
    # ];
  };

  services.resolved = {
    enable = true;
    domains = [
      "~local"
    ]; # Route local zones to our DNS
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ]; # Public fallback when local resolvers fail
    extraConfig = ''
      DNS=10.0.10.1
    '';
  };

  # Avahi for AirPrint / network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  systemd.network.networks."10-enp42s0" = {
    matchConfig.Name = "enp42s0";
    networkConfig = {
      # DHCP = "ipv4";
      VLAN = "enp42s0.50";
    };
    # dhcpV4Config.RouteMetric = 100;
    address = [
      "10.0.10.4/24"
    ];
    routes = [
      { Gateway = "10.0.10.1"; }
    ];
    dns = [ "10.0.10.1" ];
    domains = [ "~local" ];
    # make the routes on this interface a dependency for network-online.target
    linkConfig.RequiredForOnline = "routable";
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
