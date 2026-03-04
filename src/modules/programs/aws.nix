{
  flake.modules.nixos.aws = {config, ...}: let
    user = config.systemCoonstants.username;
  in {
    home-manager.users.${user}.programs.awscli = {
      enable = true;
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".aws";
          mode = "0700";
        }
      ];
    };
  };
}
