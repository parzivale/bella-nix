{
  flake.modules.nixos.mautrix-whatsapp = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    services.mautrix-whatsapp = {
      enable = true;
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
