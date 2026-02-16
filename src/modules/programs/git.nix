{
  flake.modules.nixos.git = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "${user}";
            email = "${config.systemConstants.email}";
          };
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
