{inputs, ...}: {
  flake.modules.nixos.ssh = {config, ...}: let
    user = config.vars.username;
  in {
    imports = with inputs.self.modules.nixos; [secrets openssh preservation];
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
