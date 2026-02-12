{
  vars,
  config,
  lib,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user}.programs.ssh = {
    startAgent = lib.mkDefault true;
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
