{inputs, ...}: {
  flake.modules.homeManager.lazygit = {...}: {
    programs.lazygit = {
      enable = true;
      settings.git.autoForwardBranches = "allBranches";
    };
  };

  flake.modules.nixos.lazygit = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.lazygit];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/state/lazygit";
          mode = "0755";
        }
      ];
    };
  };
}
