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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.github ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/gh";
            mode = "0700";
          }
        ];
      };
    };
in
{
  flake.modules.homeManager.github =
    { pkgs, ... }:
    {
      programs.gh = {
        enable = true;
        settings.git_protocol = "ssh";
        extensions = [ pkgs.gh-dash ];
      };
    };

  flake.modules.nixos.github = module "nixos";
  flake.modules.finix.github = module "finix";
}
