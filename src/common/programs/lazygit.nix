{vars, ...}: let
  user = vars.username;
in {
  home-manager.users.${user}.programs.lazygit.settings = {
    git.autoForwardBranches = "allBranches";
  };
}
