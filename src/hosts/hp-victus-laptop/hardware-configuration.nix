{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "sdhci_pci"];
    kernelModules = ["kvm-amd"];
  };

  fileSystems."/persistent" = {
    device = "/dev/disk/by-uuid/c27eee90-ed81-4375-6f6b-a5513573a11d";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=@persistent"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/c27eee90-ed81-4375-6f6b-a5513573a11d";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=@nix"];
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=6G" "mode=755"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7521-8BA0";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  networking.networkmanager.enable = true;

  services.xserver.videoDrivers = ["nvidia"];
  hardware = {
    bluetooth.enable = true;
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
      };
      open = true;
      prime = {
        sync.enable = true;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:6:0:0";
      };
    };
    facter.reportPath = ./facter.json;
  };
}
