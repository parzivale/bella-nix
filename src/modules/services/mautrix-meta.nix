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
    };
  in {
    services.mautrix-meta.instances = {
      instagram = {
        enable = true;
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
