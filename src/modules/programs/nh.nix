{ inputs, ... }:
let
  # The same module for nixos and finix; `class` only picks which home-manager it imports.
  module =
    class:
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.${class}.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.nh ];
    };
in
{
  flake.modules.homeManager.nh = _: {
    programs.nh.enable = true;
  };

  flake.modules.nixos.nh = module "nixos";
  flake.modules.finix.nh = module "finix";
}
