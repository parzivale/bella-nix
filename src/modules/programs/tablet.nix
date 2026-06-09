{
  flake.modules.nixos.tablet =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      hardware.opentabletdriver = {
        enable = true;
        daemon.enable = true;
      };

      preservation = config.helpers.mkPreserve user {
        directories = [
          {
            directory = ".config/OpenTableDriver";
            mode = "0755";
          }
        ];
      };
    };
}
