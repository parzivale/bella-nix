{ inputs, ... }:
{
  flake.modules.homeManager.swaync = _: {
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
      imports = [ inputs.self.modules.nixos.home-manager ];

      state.keybinds."Mod+N" = [
        "swaync-client"
        "-t"
      ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.swaync ];
    };
}
