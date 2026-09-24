{ inputs, ... }:
{
  flake.modules.homeManager.poweralertd =
    { pkgs, ... }:
    {
      systemd.user.services.poweralertd = {
        Unit = {
          Description = "UPower-powered power alerter";
          After = [
            "graphical-session.target"
            "mako.service"
          ];
          PartOf = "graphical-session.target";
        };
        Service = {
          ExecStart = "${pkgs.poweralertd}/bin/poweralertd";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

  flake.modules.nixos.poweralertd =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.poweralertd ];
    };

  # No home-manager here: the unit above is the whole of that module, and a unit
  # is the part that does not carry over. poweralertd reads upower over the system
  # bus and notifies over the session bus, so all it needs is to be running inside
  # the session.
  #
  # The nixos unit orders itself after mako. Nothing orders these, so a battery
  # warning in the first moments of a session can be sent before there is a
  # notification daemon to receive it - it is dropped, not queued.
  flake.modules.finix.poweralertd =
    { pkgs, ... }:
    {
      state.startup = [ [ "${pkgs.poweralertd}/bin/poweralertd" ] ];
    };
}
