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

      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };
}
