{
  flake.modules.nixos.spotify-player = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.spotify-player.enable = true;
  };
}
