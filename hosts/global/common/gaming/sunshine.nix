{
  pkgs,
  ...
}:
{
  services.sunshine = {
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
}
