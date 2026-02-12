{
  self,
  vars,
  ...
}: let
  user = vars.username;
in {
  flake.modules.bella.lazygit = {
    home-manager.users.${user}.programs.lazygit.settings = {
      enable = true;
      git.autoForwardBranches = "allBranches";
    };
  };
}
