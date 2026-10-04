{ ... }:
{
  # GPU access is for containers only. NixOS-WSL's useWindowsDriver already
  # links the Windows driver's libcuda/nvidia-smi into /run/opengl-driver and
  # enables hardware.graphics, and the CDI spec the toolkit generates injects
  # /dev/dxg plus the Windows driver store - no cudatoolkit or Linux driver
  # libraries on the host are needed for `docker run --device
  # nvidia.com/gpu=all`.
  #
  # No services.xserver.videoDrivers = [ "nvidia" ]: under WSL it only puts
  # the Linux driver's libcuda (which can't reach the GPU without
  # /dev/nvidia*) into /run/opengl-driver, shadowing the working Windows one.
  # The toolkit still mounts hardware.nvidia.package into containers, so
  # nvidia_x11 stays in the closure - forcing `mounts` to avoid that would
  # override module internals that shift between nixpkgs bumps.
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true;
    discovery-mode = "wsl";
    mount-nvidia-executables = false;
  };

  virtualisation.docker.enable = true;
}
