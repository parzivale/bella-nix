{ inputs, ... }:
let
  settings = {
    default-timeout = 5000;
    border-radius = 8;
    margin = "10";
    padding = "12";
    icon-path = "/run/current-system/sw/share/icons/Papirus-Dark";
  };
in
{
  flake.modules.homeManager.mako = _: {
    services.mako = {
      enable = true;
      inherit settings;
    };
  };

  flake.modules.nixos.mako =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mako ];
    };

  flake.modules.finix.mako =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      imports = [
        inputs.self.modules.finix.home-manager
        inputs.self.modules.finix.user-services
      ];

      # home-manager's mako module writes the configuration file and a user
      # service. The file is what is wanted from it; the service is inert here, so
      # the daemon is supervised as part of the session instead.
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mako ];

      providers.services.users.${user}.units.mako = {
        description = "notification daemon";

        type.service = {
          command = "${pkgs.mako}/bin/mako";

          # ready when it owns the name, not when it has been forked.
          #
          # `fork` - the default - says a notification daemon is up the moment mako exists, which
          # is before it has connected to the session bus and asked for the name. poweralertd
          # starts on that, sends its first notification into a bus where nothing answers to
          # org.freedesktop.Notifications, and waits out the method call:
          #
          #   could not send online update notification: Connection timed out
          #
          # then exits 1 and is restarted. So the first thing after a login that wants to notify
          # you pays a dbus timeout, and the daemon it was waiting for was running the whole time.
          #
          # `gdbus wait` is the question asked properly: it blocks until the name has an owner and
          # exits non-zero if it does not appear, which is what `waitFor.check` wants - the command
          # does the waiting, and giving up is its business. The timeout bounds the lie in the other
          # direction: if mako is genuinely broken, everything requiring it stops after 10s rather
          # than waiting on it for ever.
          readiness = [
            {
              waitFor.check.command = "${pkgs.glib.bin}/bin/gdbus wait --session --timeout 10 org.freedesktop.Notifications";
            }
          ];
        };
      };
    };
}
