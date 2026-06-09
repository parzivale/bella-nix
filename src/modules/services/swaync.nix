{ inputs, ... }:
{
  flake.modules.homeManager.swaync = _: {
    programs.niri.settings.binds."Mod+N".action.spawn = [
      "swaync-client"
      "-t"
    ];
    services.swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "top";
        hide-on-clear = true;
        hide-on-action = true;
        timeout = 5;
        timeout-low = 2;
        timeout-critical = 0;
      };
    };
  };

  flake.modules.nixos.swaync =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.swaync ];
    };
}
