{vars, ...}: let
  user = vars.username;
in {
  home-manager.users.${user} = {config, ...}: {
    programs.git = {
      settings = {
        user = {
          name = "${user}";
          email = "${vars.email}";
        };
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
        "credential \"https://github.com\"" = {
          username = "parzivale";
          helper = "store --file ${config.age.secrets.github-key.path}";
        };
      };
    };
  };
}
