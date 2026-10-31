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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.direnv ];

      state.preserve.users.${user} = {
        directories = [ ".local/share/direnv" ];
      };
    };
in
{
  flake.modules.homeManager.direnv = _: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # enableNushellIntegration = true;
    };
  };

  flake.modules.nixos.direnv = module "nixos";
  flake.modules.finix.direnv = module "finix";
}
