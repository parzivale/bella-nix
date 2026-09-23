{ inputs, ... }:
{
  flake.modules.homeManager.batsignal = _: {
    services.batsignal.enable = true;
  };

  flake.modules.nixos.batsignal =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.batsignal ];
    };
}
