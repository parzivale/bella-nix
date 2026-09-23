{ inputs, ... }:
{
  flake.modules.homeManager.karere =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.karere ];
    };

  flake.modules.nixos.karere =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.karere ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/karere";
            mode = "0700";
          }
        ];
      };
    };
}
