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
  };
}
