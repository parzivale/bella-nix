{
  flake.modules.nixos.lutris = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.lutris = {
        enable = true;
      };
    };
  };
}
