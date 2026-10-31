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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.tldr ];
    };
in
{
  flake.modules.homeManager.tldr =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tlrc ];
    };

  flake.modules.nixos.tldr = module "nixos";
  flake.modules.finix.tldr = module "finix";
}
