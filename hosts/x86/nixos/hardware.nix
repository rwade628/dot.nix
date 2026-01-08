{
  pkgs,
  inputs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  # Define a simple helper to generate the option string for a specific module
  # In a real scenario, these values might come from other config options
  moduleOptionString =
    moduleName: options: "options ${moduleName} ${lib.concatStringsSep " " options}";
in
{
  imports = lib.flatten [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  ## Boot ##
  boot = {
    extraModprobeConfig = ''
      options hid_apple fnmode=2

      ${moduleOptionString "nvidia" [
        # nvidia assume that by default your CPU does not support PAT,
        "NVreg_UsePageAttributeTable=1"
        # This is sometimes needed for ddc/ci support, see
        # https://www.ddcutil.com/nvidia/
        "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
      ]}'';
    loader = {
      systemd-boot = {
        enable = true;
        # When using plymouth, initrd can expand by a lot each time, so limit how many we keep around
        configurationLimit = lib.mkDefault 10;
        # Configure loader.conf to remember last booted entry
        # extraInstallCommands = ''
        #   ${pkgs.gnused}/bin/sed -i '/^default /d' /boot/loader/loader.conf
        #   echo "default @saved" >> /boot/loader/loader.conf
        # '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Use the cachyos kernel for better performance
    kernelPackages = pkgs.linuxPackages_latest;

    # Kernel sysctl parameters
    kernel.sysctl = {
      # Make swap only activate when absolutely necessary (0-200, default is 60)
      "vm.swappiness" = 1;
    };

    initrd = {
      systemd.enable = true;
      verbose = false;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [
      "kvm-amd"
    ];
    extraModulePackages = [ ];
    kernelParams = [
      # Since NVIDIA does not load kernel mode setting by default,
      # enabling it is required to make Wayland compositors function properly.
      # "nvidia-drm.fbdev=1"
      "amd_pstate=guided"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/29604a3b-d796-4e53-ae02-42f1cf46ebbf";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B060-8F8E";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/9ed738fb-4f8e-4e86-b5a4-3970ec2147d8";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/cacbfecc-0d3d-453e-a760-aef61be1d463"; }
  ];

  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    # needed by nvidia-docker
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    # package = inputs.nixpkgs-unstable.linuxPackages.nvidiaPackages.latest;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.119.02";
      sha256_64bit = "sha256-gCD139PuiK7no4mQ0MPSr+VHUemhcLqerdfqZwE47Nc=";
      sha256_aarch64 = "sha256-eYcYVD5XaNbp4kPue8fa/zUgrt2vHdjn6DQMYDl0uQs=";
      openSha256 = "sha256-l3IQDoopOt0n0+Ig+Ee3AOcFCGJXhbH1Q1nh1TEAHTE=";
      settingsSha256 = "sha256-sI/ly6gNaUw0QZFWWkMbrkSstzf0hvcdSaogTUoTecI=";
      persistencedSha256 = "sha256-j74m3tAYON/q8WLU9Xioo3CkOSXfo1CwGmDx/ot0uUo=";
    };
  };

  # Fixes issue with glitchy screen after resume from suspend
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
}

# STUFF ABOUT CHAOTIC NIX CACHE
# nix eval 'github:chaotic-cx/nyx/nyxpkgs-unstable#linuxPackages_cachyos.kernel.outPath'
# nix eval 'chaotic#linuxPackages_cachyos.kernel.outPath'
# nix eval '<HOME>/git/Nix/dot.nix#nixosConfigurations.rune.config.boot.kernelPackages.kernel.outPath'
# curl -L 'https://chaotic-nyx.cachix.org/{{HASH}}.narinfo'
# sudo nixos-rebuild switch --flake ./git/Nix/dot.nix/. --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
