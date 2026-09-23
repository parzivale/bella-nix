_: {
  flake.modules.nixos.iwd = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        # nixpkgs passes upstream's `false` through, and iwd is the only thing
        # here that would configure the link.
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

    state.preserve.directories = [
      "/var/lib/iwd"
    ];
  };

  flake.modules.finix.iwd =
    { modules, ... }:
    {
      # iwd is not part of finix's base system, so the host asks for the module
      # as well as the service.
      imports = [ modules.iwd ];

      # Enabling it is the whole of the configuration. finix's own module
      # defaults `General.EnableNetworkConfiguration` on for the same reason the
      # nixos side sets it, and picks `Network.NameResolvingService` from
      # whether `programs.resolvconf` is enabled — "systemd" is not an answer
      # available here.
      #
      # Nothing corresponds to the networkd rule above either: there is no
      # networkd to compete with for IP configuration.
      services.iwd.enable = true;

      state.preserve.directories = [
        "/var/lib/iwd"
      ];
    };
}
