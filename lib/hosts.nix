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
        # Pre-existing macOS account; nix-darwin can't create accounts, so this
        # must match the account already on the machine. Config, secrets, and
        # the shared home-manager module still key off `name` ("ryan") above.
        osName = "rdubs628";
      };
      hasDesktop = true;
    };
  };
}
