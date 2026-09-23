{ inputs, ... }:
{
  flake.modules.homeManager.wine =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        fex-headless
        wineWow64Packages.stagingFull
      ];
    };

  flake.modules.nixos.wine =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.wine ];

      state.preserve.users.${user} = {
        directories = [ { directory = ".wine"; } ];
      };
    };
}
