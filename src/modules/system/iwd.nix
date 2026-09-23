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

      # finix's own module defaults `General.EnableNetworkConfiguration` on for
      # the same reason the nixos side sets it, so enabling the service is the
      # whole of the configuration.
      services.iwd.enable = true;

      # `Network.NameResolvingService` is chosen from whether this is on -
      # "systemd" is not an answer available here - and without a resolver iwd
      # brings a connection up with an address and no dns. Named here rather
      # than assumed from whatever else the host imports.
      programs.resolvconf.enable = true;

      # The networkd rule on the nixos side has moved rather than disappeared:
      # iwd configures wireless itself on both classes, so the dhcp client has
      # to be kept off those interfaces. That guard lives with the client, in
      # the network module.

      state.preserve.directories = [
        "/var/lib/iwd"
      ];
    };
}
