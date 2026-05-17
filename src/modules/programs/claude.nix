{inputs, ...}: {
  flake.modules.homeManager.claude = {...}: {
    programs.claude-code.enable = true;
  };

  flake.modules.nixos.claude = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.claude];

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
