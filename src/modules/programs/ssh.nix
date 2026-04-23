{inputs, ...}: {
  flake.modules.nixos.ssh = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = with inputs.self.modules.nixos; [secrets openssh preservation];

    age.secrets.github-key = {
      rekeyFile = ../../secrets/github/github-key.age;
      owner = user;
    };
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
          controlMaster = "auto";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "15m";
        };
      };
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
