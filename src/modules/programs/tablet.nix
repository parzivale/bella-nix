{
  flake.modules.nixos.tablet =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      hardware.opentabletdriver = {
        enable = true;
        daemon.enable = true;
      };

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/OpenTableDriver";
            mode = "0755";
          }
        ];
      };
    };
}
