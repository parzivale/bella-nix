{vars, ...}: let
  user = vars.username;
in {
  flake.modules.bella.git = {
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
