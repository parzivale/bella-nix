{inputs}: {
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
    kernelParams = ["video=eDP-1:d"];
  };

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
