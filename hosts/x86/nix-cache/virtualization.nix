# Virtualisation stack (Docker, libvirt, Incus)
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.distrobox ];
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.incus.enable = true;
  programs.virt-manager.enable = true;

  # TODO move off incus/truenas
  nixpkgs.config.permittedInsecurePackages = [
    "minio-2025-10-15T17-29-55Z"
  ];
}
