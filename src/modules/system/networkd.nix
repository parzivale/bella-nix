{
  flake.modules.nixos.networkd = {
    networking.useDHCP = false;
    networking.dhcpcd.enable = false;

    systemd.network.enable = true;
    systemd.network.networks."10-networkd" = {
      matchConfig.Name = "en* eth* wl*";
      networkConfig.DHCP = "yes";
    };
  };
}
