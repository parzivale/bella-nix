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
  # the session - and to be told that a notification daemon is there to receive
  # what it sends, which the nixos unit says with `After = mako.service` and this
  # says with `requires`.
  flake.modules.finix.poweralertd =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.finix.graphical-session
        # Named in `requires` below, so the unit has to exist - the same coupling
        # the nixos unit already has with `After = mako.service`.
        inputs.self.modules.finix.mako
      ];

      session.services.poweralertd = {
        description = "UPower-powered power alerter";
        command = [ "${pkgs.poweralertd}/bin/poweralertd" ];
        requires = [ "mako" ];
      };
    };
}
