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

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.yazi ];
    };
in
{
  flake.modules.homeManager.yazi = _: {
    programs.yazi = {
      shellWrapperName = "yy";
      enable = true;
      settings = {
        mgr = {
          linemode = "mtime";
        };
        input = {
          create_origin = "bottom-left";
          cd_origin = "bottom-left";
          rename_origin = "bottom-left";
          filter_origin = "bottom-left";
          search_origin = "bottom-left";
          shell_origin = "bottom-left";
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = "d";
            run = "remove --permanently";
          }
        ];
      };
    };
  };

  flake.modules.nixos.yazi = module "nixos";
  flake.modules.finix.yazi = module "finix";
}
