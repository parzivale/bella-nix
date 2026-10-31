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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.lazygit ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/state/lazygit";
            mode = "0755";
          }
        ];
      };
    };
in
{
  flake.modules.homeManager.lazygit = _: {
    programs.lazygit = {
      enable = true;
      settings.git.autoForwardBranches = "allBranches";
    };
  };

  flake.modules.nixos.lazygit = module "nixos";
  flake.modules.finix.lazygit = module "finix";
}
