{
  flake.modules.nixos.pocket-id = {config, ...}: let
    pocket-id_domain = config.systemConstants.subDomains.pocket-id;
    pocket-id_port = config.systemConstants.ports.pocket-id;
  in {
    age.secrets.pocket-id-env = {
      rekeyFile = ../../secrets/pocket-id/pocket-id.age;
      owner = "pocket-id";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/pocket-id 0750 pocket-id pocket-id -"
    ];

    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://${pocket-id_domain}";
        TRUST_PROXY = true;
        DB_CONNECTION_STRING = "\"postgresql:///pocket-id?host=/run/postgresql\"";
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

    services.nginx.virtualHosts."${pocket-id_domain}" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString pocket-id_port}";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/pocket-id";
      }
    ];
  };
}
