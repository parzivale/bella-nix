{
  flake.modules.nixos.mautrix-gmessages = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    age.secrets.mautrix-gmessages-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-gmessages.age;
      owner = "mautrix-gmessages";
    };

    systemd.services.mautrix-gmessages-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-gmessages = {
      enable = true;
      environmentFile = config.age.secrets.mautrix-gmessages-env.path;
      settings = {
        homeserver = {
          address = "https://matrix.${domain}";
          inherit domain;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-gmessages?host=/run/postgresql";
        };
        bridge.permissions."${domain}" = "user";
        encryption = {
          allow = true;
          msc4190 = true;
          pickle_key = "$ENCRYPTION_PICKLE_KEY";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-gmessages"];
      ensureUsers = [{name = "mautrix-gmessages"; ensureDBOwnership = true;}];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-gmessages";}
    ];
  };
}
