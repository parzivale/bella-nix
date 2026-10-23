{ inputs, ... }:
{
  flake.modules.homeManager.obs =
    { ... }:
    {
      programs.obs-studio.enable = true;
    };

  flake.modules.nixos.obs =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      # the screencast portal is what serves OBS's screen capture source
      imports = with inputs.self.modules.nixos; [
        home-manager
        xdg-desktop-portal-screencast
      ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.obs ];

      state.preserve.users.${user} = {
        directories = [ { directory = ".config/obs-studio"; } ];
      };
    };

  flake.modules.finix.obs =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      # the screencast portal is what serves OBS's screen capture source
      imports = with inputs.self.modules.finix; [
        home-manager
        xdg-desktop-portal-screencast
      ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.obs ];

      state.preserve.users.${user} = {
        directories = [ { directory = ".config/obs-studio"; } ];
      };
    };
}
