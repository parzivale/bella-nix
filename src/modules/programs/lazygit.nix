{
  flake.modules.nixos.lazygit = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.lazygit.settings = {
      enable = true;
      git.autoForwardBranches = "allBranches";
    };
  };
}
