{
  flake.modules.nixos.avahi = {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        domain = true;
        addresses = true;
        userServices = true;
      };
    };
  };

  flake.modules.finix.avahi =
    { modules, ... }:
    {
      imports = [ modules.avahi ];

      services.avahi = {
        enable = true;

        # nixpkgs' `publish` submodule is a convenience over avahi-daemon.conf's
        # [publish] section; finix takes the file's own keys, so the same four
        # choices are spelled the way avahi reads them. Strings rather than
        # booleans: the ini generator would write `true`, and avahi wants `yes`.
        settings.publish = {
          disable-publishing = "no";
          disable-user-service-publishing = "no";
          publish-addresses = "yes";
          publish-domain = "yes";
        };
      };

      # `nssmdns4` has no counterpart. On NixOS it adds `mdns4_minimal` to
      # nsswitch through `system.nssModules`/`system.nssDatabases`; finix writes
      # /etc/nsswitch.conf as literal text in its environment module with no
      # option to extend it, so the only way in would be an `mkForce` rewrite of
      # the whole file from here.
      #
      # So avahi advertises this host and resolves through its own tooling, but
      # glibc will not resolve .local names. Worth an nsswitch option upstream
      # before any finix host of mine needs mdns resolution.
    };
}
