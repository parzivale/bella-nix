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
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.batsignal ];
    };
}
