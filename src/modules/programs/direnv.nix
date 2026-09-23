{ inputs, ... }:
{
  flake.modules.homeManager.direnv = _: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # enableNushellIntegration = true;
    };
  };

  flake.modules.nixos.direnv =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.direnv ];

      state.preserve.users.${user} = {
        directories = [ ".local/share/direnv" ];
      };
    };

  flake.modules.finix.direnv =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.direnv ];

      state.preserve.users.${user} = {
        directories = [ ".local/share/direnv" ];
      };
    };
}
