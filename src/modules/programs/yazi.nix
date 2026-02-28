{
  flake.modules.nixos.yazi = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.yazi = {
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
  };
}
