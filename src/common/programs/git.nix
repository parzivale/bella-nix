{
  vars,
  config,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    programs.git = {
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
}
