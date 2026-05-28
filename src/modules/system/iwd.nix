{...}: {
  flake.modules.nixos.iwd = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General.EnableNetworkConfiguration = true;
        Network.NameResolvingService = "systemd";
      };
    };

    # Prevent networkd from competing with iwd for IP config on wireless interfaces
    systemd.network.networks."05-wireless-iwd" = {
      matchConfig.Name = "wl*";
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = "no";
      };
    };

    preservation.preserveAt."/persistent".directories = [
      "/var/lib/iwd"
    ];
  };
}
