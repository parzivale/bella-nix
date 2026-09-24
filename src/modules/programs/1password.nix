{ inputs, ... }:
let
  # Where 1Password keeps its vault cache and the CLI its account config. Both
  # 0700: the whole point of the directories is that only this user reads them.
  preserve = user: {
    state.preserve.users.${user} = {
      directories = [
        {
          directory = ".config/1Password";
          mode = "0700";
        }
        {
          directory = ".config/op";
          mode = "0700";
        }
      ];
    };
  };
in
{
  flake.modules.nixos._1password =
    { config, ... }:
    let
      user = config.constants.username;
    in
    preserve user
    // {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ user ];
      };
    };

  # finix had neither module; both are there now and say the same two things.
  flake.modules.finix._1password =
    {
      config,
      modules,
      ...
    }:
    let
      user = config.constants.username;
    in
    preserve user
    // {
      imports = [
        modules._1password
        modules._1password-gui
      ];

      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ user ];
      };
    };
}
