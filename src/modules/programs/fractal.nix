{ inputs, ... }:
{
  flake.modules.homeManager.fractal =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fractal ];
    };

  flake.modules.nixos.fractal =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.fractal ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/fractal";
            mode = "0700";
          }
        ];
      };
    };
}
