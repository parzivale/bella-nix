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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.nushell ];
    };
in
{
  flake.modules.homeManager.nushell =
    {
      programs = {
        lazygit.enableNushellIntegration = true;
        # I would rather rename it myself
        # yazi.enableNushellIntegration = true;
        zoxide.enableNushellIntegration = true;
        starship.enableNushellIntegration = true;
        nushell = {
          enable = true;
          configFile.source = ./configuration.nu;
          loadSessionVariables = true;
          settings = {
            show_banner = false;
          };
        };
      };
      home.shell.enableNushellIntegration = true;
    };

  flake.modules.nixos.nushell = module "nixos";
  flake.modules.finix.nushell = module "finix";
}
