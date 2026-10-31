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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.blender ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/blender";
            mode = "0755";
          }
        ];
      };
    };
in
{
  flake.modules.homeManager.blender =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];
    };

  flake.modules.nixos.blender = module "nixos";
  flake.modules.finix.blender = module "finix";
}
