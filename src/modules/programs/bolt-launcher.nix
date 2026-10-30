{ inputs, ... }:
let
  # Bolt keeps the Jagex login and its settings in these, and starts RuneLite with
  # `user.home` pointed at the data one, so `.runelite` - plugins, profiles - lives
  # there too.
  preserve = user: {
    state.preserve.users.${user} = {
      directories = [
        {
          directory = ".local/share/bolt-launcher";
          mode = "0700";
        }
        {
          directory = ".config/bolt-launcher";
          mode = "0700";
        }
      ];
    };
  };
in
{
  flake.modules.homeManager.bolt-launcher =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bolt-launcher ];
    };

  flake.modules.nixos.bolt-launcher =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.bolt-launcher ];
    }
    // preserve user;

  flake.modules.finix.bolt-launcher =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.bolt-launcher ];
    }
    // preserve user;
}
