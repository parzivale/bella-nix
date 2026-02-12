{
  vars,
  config,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user}.programs.ssh = {
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = config.age.secrets.github-key.path;
        identitiesOnly = true;
      };
    };
  };
}
