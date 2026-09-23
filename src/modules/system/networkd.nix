{
  flake.modules.nixos.networkd = {
    networking.useDHCP = false;
    networking.dhcpcd.enable = false;

    systemd.network.enable = true;
    systemd.network.wait-online.anyInterface = true;
    systemd.network.networks."10-networkd" = {
      matchConfig.Name = "en* eth* wl*";
      networkConfig.DHCP = "yes";
    };
  };

  # Not a port: systemd-networkd does not exist here, so this is the same
  # intent - DHCP on the wired and wireless interfaces, nothing else - asked of
  # the client finix does have. iwd takes its own wireless interfaces back in
  # the iwd module, which is where that belongs.
  flake.modules.finix.networkd =
    { modules, ... }:
    {
      imports = [ modules.dhcpcd ];

      services.dhcpcd.enable = true;
    };
}
