{ inputs, ... }:
{
  # NetworkManager for every interface - wired and wifi - with wpa_supplicant as its wifi backend.
  # In place of iwd for wifi and dhcpcd for wired: one thing owns each interface, which is what
  # a desktop wants, and it is what nmcli and the applets talk to.
  flake.modules.finix.networkmanager =
    { modules, ... }:
    {
      imports = [
        modules.networkmanager
        inputs.self.modules.finix.wpa_supplicant
      ];

      services.networkmanager.enable = true;

      # NetworkManager leases addresses on the wired interfaces itself, so the dhcpcd the
      # `network` module runs would be a second client on the same link.
      services.dhcpcd.enable = false;

      # NetworkManager hands dns to resolvconf when it is on - finix's module picks
      # `rc-manager=resolvconf` from this - and `network` already enables it; said here too so
      # this module does not depend on being imported beside that one.
      programs.resolvconf.enable = true;

      # saved connections, secrets included, and the leases and state NetworkManager keeps
      # between boots. Not /var/lib/iwd's networks: those do not carry over and are added again.
      state.preserve.directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
      ];
    };
}
