{inputs}: {lib, ...}: {
  networking = {
    useDHCP = false;
    interfaces.enp3s0 = {
      ipv4.addresses = [
        {
          address = "130.240.204.12";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:6b0:10:9829:204:12";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "130.240.204.1";
      interface = "enp3s0";
    };
    defaultGateway6 = {
      address = "2001:6b0:10:9829::1";
      interface = "enp3s0";
    };
  };

  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
