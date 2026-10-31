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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.starship ];
    };
in
{
  flake.modules.homeManager.starship = _: {
    programs.starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[❯](green)";
          error_symbol = "[❯](green)";
        };
        cmd_duration = {
          min_time = 1000;
          format = "in [$duration](bold yellow) ";
        };
        directory = {
          read_only = " ";
          style = "bold white";
          read_only_style = "bold yellow";
          truncation_length = 8;
          truncation_symbol = "…/";
        };
        username = {
          format = "[\\[](bold red)[$user](bold yellow)";
          disabled = false;
          show_always = true;
        };
        hostname = {
          ssh_only = false;
          format = "[@](bold green)[$hostname](bold blue)[\\]](bold purple) ";
          trim_at = ".companyname.com";
          disabled = false;
        };
      };
    };
  };

  flake.modules.nixos.starship = module "nixos";
  flake.modules.finix.starship = module "finix";
}
