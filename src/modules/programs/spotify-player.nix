{ inputs, ... }:
{
  flake.modules.homeManager.spotify-player = _: {
    programs.spotify-player.enable = true;

    xdg.desktopEntries.spotify-player = {
      name = "Spotify";
      icon = "spotify";
      exec = "spotify_player";
      terminal = true;
      categories = [
        "Audio"
        "Music"
      ];
    };
  };

  flake.modules.nixos.spotify-player =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.spotify-player ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".cache/spotify-player";
            mode = "0755";
          }
        ];
      };
    };

  flake.modules.finix.spotify-player =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.spotify-player ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".cache/spotify-player";
            mode = "0755";
          }
        ];
      };
    };
}
