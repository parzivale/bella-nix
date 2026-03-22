{
  flake.modules.nixos.spotify-player = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.spotify-player.enable = true;

      xdg.desktopEntries.spotify-player = {
        name = "Spotify";
        icon = "spotify";
        exec = "spotify_player";
        terminal = true;
        categories = ["Audio" "Music"];
      };
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".cache/spotify-player";
          mode = "0755";
        }
      ];
    };
  };
}
