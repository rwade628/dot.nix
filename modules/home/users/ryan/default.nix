{
  lib,
  host,
  pkgs,
  ...
}:
{
  imports = [
    (lib.custom.relativeToRoot "modules/home/core")
    # (lib.optionalAttrs (!host.isServer) ./theme)
    (lib.custom.relativeToRoot "modules/home/hosts/${host.network.hostName}")
  ];
}
