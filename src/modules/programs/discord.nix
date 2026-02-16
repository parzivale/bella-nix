{
  flake.modules.nixos.git = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.discord = {
        enable = true;
      };
    };
  };
}
