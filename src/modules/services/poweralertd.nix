{ inputs, ... }:
{
  flake.modules.homeManager.poweralertd =
    { pkgs, ... }:
    {
      systemd.user.services.poweralertd = {
        description = "UPower-powered power alerter";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.poweralertd}/bin/poweralertd";
          Restart = "on-failure";
          RestartSec = 1;
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
