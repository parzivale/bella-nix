{
  flake.modules.nixos.mautrix-discord = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    services.mautrix-discord = {
      enable = true;
      settings = {
        homeserver = {
          address = "http://127.0.0.1:8008";
          inherit domain;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-discord?host=/run/postgresql";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-discord"];
      ensureUsers = [{name = "mautrix-discord"; ensureDBOwnership = true;}];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-discord";}
    ];
  };
}
