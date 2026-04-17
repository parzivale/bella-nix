{
  flake.modules.nixos.pocket-id = {config, ...}: let
    domain = config.systemConstants.domain;
  in {
    age.secrets.pocket-id-env = {
      rekeyFile = ../../secrets/pocket-id/pocket-id.age;
      owner = "pocket-id";
    };

    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://id.${domain}";
        TRUST_PROXY = true;
        DB_CONNECTION_STRING = "postgresql:///pocket-id?host=/run/postgresql";
      };
      environmentFile = config.age.secrets.pocket-id-env.path;
    };

    services.postgresql = {
      ensureDatabases = ["pocket-id"];
      ensureUsers = [
        {
          name = "pocket-id";
          ensureDBOwnership = true;
        }
      ];
    };

    services.nginx.virtualHosts."id.${domain}" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:1411";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/pocket-id";
        user = "pocket-id";
        group = "pocket-id";
      }
    ];
  };
}
