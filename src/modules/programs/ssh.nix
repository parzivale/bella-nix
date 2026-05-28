{inputs, ...}: {
  flake.modules.homeManager.ssh = {osConfig, ...}: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = osConfig.age.secrets.github-key.path;
          IdentitiesOnly = true;
        };

        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "15m";
        };
      };
    };
  };

  flake.modules.nixos.ssh = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = with inputs.self.modules.nixos; [secrets openssh preservation];

    age.secrets.github-key = {
      rekeyFile = ../../secrets/github/github-key.age;
      owner = user;
    };

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.ssh];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".ssh"; mode = "0700";}];
    };
  };
}
