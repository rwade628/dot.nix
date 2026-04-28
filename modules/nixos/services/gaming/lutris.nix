{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    (lutris.override {
      extraPkgs = pkgs: [
        wineWow64Packages.waylandFull
        winetricks
        vulkan-tools
        xterm
      ];
    })
  ];
  nixpkgs.overlays = [
    (_: prev: {
      openldap = prev.openldap.overrideAttrs {
        doCheck = !prev.stdenv.hostPlatform.isi686;
      };
    })
  ];
}
