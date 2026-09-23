{ inputs, ... }:
{
  flake.modules.homeManager.blender =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];
    };

  flake.modules.nixos.blender =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.blender ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/blender";
            mode = "0755";
          }
        ];
      };
    };
}
