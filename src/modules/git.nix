{
  self,
  vars,
  ...
}: let
  user = vars.username;
in {
  flake.modules.bella.git = {
    imports = [self.modules.bella.ssh self.modules.bella.home-manager];
    home-manager.users.${user} = {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "${user}";
            email = "${vars.email}";
          };
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
