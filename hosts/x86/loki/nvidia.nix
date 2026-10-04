{ ... }:
{
  # GPU access is for containers only. NixOS-WSL's useWindowsDriver already
  # links the Windows driver's libcuda/nvidia-smi into /run/opengl-driver and
  # enables hardware.graphics, and the CDI spec the toolkit generates injects
  # /dev/dxg plus the Windows driver store - no cudatoolkit or Linux driver
  # libraries on the host are needed for `docker run --device
  # nvidia.com/gpu=all`.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = false;
  };

  virtualisation.docker.enable = true;
}
