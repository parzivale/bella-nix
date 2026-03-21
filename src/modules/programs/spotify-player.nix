{
  flake.modules.nixos.spotify-player = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.spotify-player.enable = true;

      xdg.desktopEntries.spotify-player = {
        name = "Spotify";
        exec = "spotify_player";
        terminal = true;
        categories = ["Audio" "Music"];
      };
    };
  };
}
