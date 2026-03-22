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
    kernelModules = ["kvm-amd" "btusb"];
    kernelParams = ["video=eDP-1:d"];
    blacklistedKernelModules = ["serial_8250"];
    loader.timeout = 0;
  };

  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [];
  networking.useNetworkd = true;

  hardware = {
    firmware = with pkgs; [linux-firmware];
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
    graphics.enable = true;
    graphics.enable32Bit = true;
    nvidia = {
      powerManagement = {
        enable = true;
      };
      prime = {
        sync.enable = true;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:6:0:0";
      };
    };

    facter.reportPath = ./facter.json;
  };
}
