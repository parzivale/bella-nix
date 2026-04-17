{
  flake.modules.nixos.mautrix-telegram = {
    config,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    services.mautrix-telegram = {
      enable = true;
      settings = {
        homeserver = {
          address = "http://127.0.0.1:8008";
          inherit domain;
          software = "standard";
        };
        appservice = {
          database = "postgresql+psycopg2:///mautrix-telegram?host=/run/postgresql";
          port = 29317;
          address = "http://localhost:29317";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-telegram"];
      ensureUsers = [{name = "mautrix-telegram"; ensureDBOwnership = true;}];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-telegram";}
    ];
  };
}
