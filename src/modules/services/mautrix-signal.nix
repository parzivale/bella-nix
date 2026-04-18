{
  flake.modules.nixos.mautrix-signal = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    age.secrets.mautrix-signal-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-signal.age;
      owner = "mautrix-signal";
    };

    systemd.services.mautrix-signal-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-signal = {
      enable = true;
      environmentFile = config.age.secrets.mautrix-signal-env.path;
      settings = {
        homeserver = {
          address = "http://127.0.0.1:8008";
          inherit domain;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-signal?host=/run/postgresql";
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
      ensureDatabases = ["mautrix-signal"];
      ensureUsers = [{name = "mautrix-signal"; ensureDBOwnership = true;}];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-signal";}
    ];
  };
}
