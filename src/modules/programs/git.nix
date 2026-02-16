{
  flake.modules.nixos.git = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.git = {
        enable = true;
        settings = {
          url = {
            "git@github.com" = {
              insteadOf = "https://github.com/";
            };
          };
          user = {
            name = "parzivale";
            email = "zeus@theolivers.org";
          };
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
