# Constants data implementation (host configuration)
# Non-sensitive configuration values for hosts
{
  ...
}:
{
  # No need to import spec here - it's imported in evalModules

  hostSpec = {
    ## X86 Hosts ##
    nixos = {
      network = {
        hostName = "nixos";
      };
      user = {
        name = "ryan";
      };
      mounts = {
        media = true;
      };
      plasma = true;
    };
    nix-cache = {
      network = {
        hostName = "nix-cache";
      };
      user = {
        name = "ryan";
      };
    };
    loki = {
      network = {
        hostName = "loki";
      };
      user = {
        name = "ryan";
      };
      mounts = {
        media = true;
      };
      isServer = true;
    };

    ## Darwin Hosts ##
    idun = {
      network = {
        hostName = "idun";
      };
      user = {
        name = "ryan";
      };
      hasDesktop = true;
    };
  };
}
