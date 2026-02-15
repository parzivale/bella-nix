{
  flake.modules.nixos.lazygit = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.lazygit = {
      enableNushellIntegration = true;
      settings = {
        enable = true;
        git.autoForwardBranches = "allBranches";
      };
    };
  };
}
