{
  flake.modules.nixos.claude = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.claude-code = {
      enable = true;
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".claude";
          mode = "0755";
        }
      ];
      files = [
        {
          file = ".claude.json";
        }
      ];
    };
  };
}
