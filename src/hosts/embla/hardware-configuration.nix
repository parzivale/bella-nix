{inputs}: {lib, ...}: {
  networking = {
    useDHCP = false;
    dhcpcd.enable = false;
  };

  systemd.network = {
    enable = true;
    networks."10-enp3s0" = {
      matchConfig.Name = "enp3s0";

      address = [
        "130.240.202.212/24"
      ];

      routes = [
        {Gateway = "130.240.202.1";}
      ];

      networkConfig = {
        DHCP = "no";
      };
    };
  };
  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
