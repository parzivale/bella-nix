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
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.tldr ];
    };
}
