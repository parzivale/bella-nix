{ inputs, ... }:
{
  flake.modules.homeManager.ssh =
    { osConfig, ... }:
    {
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

          "tangled.sh" = {
            HostName = "tangled.sh";
            User = "git";
            IdentityFile = osConfig.age.secrets.tangled-key.path;
            IdentitiesOnly = true;
          };

          "tangled.org" = {
            HostName = "tangled.org";
            User = "git";
            IdentityFile = osConfig.age.secrets.tangled-key.path;
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

  flake.modules.nixos.ssh =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = with inputs.self.modules.nixos; [
        secrets
        openssh
        preservation
        home-manager
      ];

      age.secrets.github-key = {
        rekeyFile = ../../secrets/master/github/github-key.age;
        owner = user;
      };

      age.secrets.tangled-key = {
        rekeyFile = ../../secrets/master/tangled/tangled-key.age;
        owner = user;
      };

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.ssh ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".ssh";
            mode = "0700";
          }
        ];
      };
    };

  flake.modules.finix.ssh =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = with inputs.self.modules.finix; [
        secrets
        openssh
        preservation
        home-manager
        user-services
      ];

      # What `programs.ssh.startAgent = true` was on the nixos side, and what went missing when
      # it was moved to `home-manager.users.<user>.programs.ssh.startAgent` - an option
      # home-manager does not have, so the line evaluated to nothing and was then deleted. The
      # client configuration below survived that move; the agent did not.
      #
      # It is wanted for the yubikey specifically. `secrets/yubikey/yubikey_sshkey_usb{a,c}.pub`
      # are `sk-ssh-ed25519@openssh.com` resident keys, and the only way to use a resident key
      # is `ssh-add -K`, which loads it from the token *into an agent*. Without one there is
      # nothing for that command to talk to.
      programs.ssh.startAgent = true;

      age.secrets.github-key = {
        rekeyFile = ../../secrets/master/github/github-key.age;
        owner = user;
      };

      age.secrets.tangled-key = {
        rekeyFile = ../../secrets/master/tangled/tangled-key.age;
        owner = user;
      };

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.ssh ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".ssh";
            mode = "0700";
          }
        ];
      };
    };
}
