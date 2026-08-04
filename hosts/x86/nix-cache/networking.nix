# Network configuration for nix-cache
{ ... }:

{
  networking.nftables.enable = true;
  networking.firewall.enable = true;

  # --- Firewall ---
  networking.firewall.allowedTCPPorts = [
    5000 # Harmonia binary cache
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      Domains = [
        "~local"
        "~casadewade.com"
      ]; # Route local zones to our DNS
      DNS = [
        "10.0.10.1"
      ];
    };
  };
}
