{ inputs, ... }:
{
  flake.modules.homeManager.nh = _: {
    programs.nh.enable = true;
  };

  flake.modules.nixos.nh =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.nh ];
    };

  flake.modules.finix.nh =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.nh ];
    };
}
