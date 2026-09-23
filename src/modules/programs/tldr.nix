{ inputs, ... }:
{
  flake.modules.homeManager.tldr =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tlrc ];
    };

  flake.modules.nixos.tldr =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.tldr ];
    };

  flake.modules.finix.tldr =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.tldr ];
    };
}
