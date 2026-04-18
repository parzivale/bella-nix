{
  flake.modules.nixos.mautrix-whatsapp = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    age.secrets.mautrix-whatsapp-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-whatsapp.age;
      owner = "mautrix-whatsapp";
    };

    systemd.services.mautrix-whatsapp-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-whatsapp = {
      enable = true;
      environmentFile = config.age.secrets.mautrix-whatsapp-env.path;
      settings = {
        homeserver = {
          address = "http://127.0.0.1:8008";
          inherit domain;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
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
      ensureDatabases = ["mautrix-whatsapp"];
      ensureUsers = [{name = "mautrix-whatsapp"; ensureDBOwnership = true;}];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-whatsapp";}
    ];
  };
}
