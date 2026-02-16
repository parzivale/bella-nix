{
  flake.modules.nixos.git = {config, ...}: let
    user = config.vars.username;
  in {
    home-manager.users.${user} = {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "${user}";
            email = "${config.vars.email}";
          };
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
