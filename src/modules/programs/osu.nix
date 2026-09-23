{ inputs, ... }:
{
  flake.modules.homeManager.osu =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.osu-lazer-bin ];
    };

  flake.modules.nixos.osu =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.osu ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/osu";
            mode = "0755";
          }
        ];
      };
    };
}
