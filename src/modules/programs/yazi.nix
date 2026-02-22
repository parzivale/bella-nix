{
  flake.modules.nixos.yazi = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.yazi = {
        enable = true;
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
