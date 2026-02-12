{
  self,
  vars,
  ...
}: let
  user = vars.username;
in {
  flake.modules.bella.lazygit = {
    inputs = [self.modules.bella.home-manager];
    home-manager.users.${user}.programs.lazygit.settings = {
      enable = true;
      git.autoForwardBranches = "allBranches";
    };
  };
}
