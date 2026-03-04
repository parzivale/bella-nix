{
  flake.modules.nixos.awscli = {config, ...}: let
    user = config.systemConstants.username;
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
