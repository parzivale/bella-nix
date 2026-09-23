{ inputs, ... }:
{
  flake.modules.homeManager.cinny =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.cinny-desktop ];
    };

  flake.modules.nixos.cinny =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.cinny ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/cinny";
            mode = "0700";
          }
        ];
      };
    };
}
