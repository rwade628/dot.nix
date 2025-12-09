# Dynamic NFS mount configuration based on host specifications
{
  ...
}:
{
  # Ensure NFS client support
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  # Configure systemd mounts
  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "nfsvers=4.2,noatime,soft,intr";
      };
      what = "10.0.10.3:/mnt/storage/k8s/media";
      where = "/mnt/media";
    }
  ];

  # Configure systemd automounts
  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/media";
    }
  ];
}
