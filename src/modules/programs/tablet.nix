{
  flake.modules.nixos.tablet = {config, ...}: let
    user = config.systemConstants.username;
  in {
    hardware.opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".config/OpenTableDriver";
          mode = "0755";
        }
      ];
    };
  };
}
