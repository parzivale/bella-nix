{
  flake.modules.nixos.mautrix-meta = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
    homeserver = {
      address = "http://127.0.0.1:8008";
      inherit domain;
      software = "standard";
    };
    encryption = {
      allow = true;
      msc4190 = true;
      pickle_key = "$ENCRYPTION_PICKLE_KEY";
    };
  in {
    age.secrets.mautrix-instagram-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-instagram.age;
      owner = "mautrix-meta-instagram";
    };
    age.secrets.mautrix-facebook-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-facebook.age;
      owner = "mautrix-meta-facebook";
    };

    systemd.services.mautrix-meta-instagram-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };
    systemd.services.mautrix-meta-facebook-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-meta.instances = {
      instagram = {
        enable = true;
        environmentFile = config.age.secrets.mautrix-instagram-env.path;
        settings = {
          homeserver = homeserver;
          encryption = encryption;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-meta-instagram?host=/run/postgresql";
          };
          bridge.permissions."${domain}" = "user";
        };
      };
      facebook = {
        enable = true;
        environmentFile = config.age.secrets.mautrix-facebook-env.path;
        settings = {
          homeserver = homeserver;
          encryption = encryption;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-meta-facebook?host=/run/postgresql";
          };
          bridge.permissions."${domain}" = "user";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-meta-instagram" "mautrix-meta-facebook"];
      ensureUsers = [
        {name = "mautrix-meta-instagram"; ensureDBOwnership = true;}
        {name = "mautrix-meta-facebook"; ensureDBOwnership = true;}
      ];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-meta-instagram";}
      {directory = "/var/lib/mautrix-meta-facebook";}
    ];
  };
}
