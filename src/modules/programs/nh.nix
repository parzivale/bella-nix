{ inputs, ... }:
{
  flake.modules.homeManager.nh = _: {
    programs.nh.enable = true;
  };

  flake.modules.nixos.nh =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.nh ];
    };
}
