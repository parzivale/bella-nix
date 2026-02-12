{
  self,
  vars,
  config,
  ...
}: let
  user = vars.username;
in {
  flake.modules.bella.ssh = {
    import = with self.modules.bella; [secrets openssh];
    home-manager.users.${user}.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
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

    preservation.users.${user} = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
