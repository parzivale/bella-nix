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
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.poweralertd ];
    };
}
