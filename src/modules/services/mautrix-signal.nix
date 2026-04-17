{
  flake.modules.nixos.mautrix-signal = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    services.mautrix-signal = {
      enable = true;
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
