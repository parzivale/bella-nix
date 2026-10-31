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
in
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

  flake.modules.nixos.spotify-player = module "nixos";
  flake.modules.finix.spotify-player = module "finix";
}
