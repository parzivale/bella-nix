{inputs, ...}: {
  flake.modules.homeManager.spotify-player = {...}: {
    programs.spotify-player.enable = true;

    xdg.desktopEntries.spotify-player = {
        name = "Spotify";
        icon = "spotify";
        exec = "spotify_player";
        terminal = true;
        categories = ["Audio" "Music"];
      };
  };

  flake.modules.nixos.spotify-player = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.spotify-player];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".cache/spotify-player"; mode = "0755";}];
    };
  };
}
