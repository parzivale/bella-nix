{
  flake.modules.nixos.synapse = {
    config,
    pkgs,
    ...
  }: let
    domain = config.systemConstants.domain;
  in {
    age.secrets.synapse-secret = {
      rekeyFile = ../../secrets/synapse-secrets/synapse-secrets.age;
      owner = "matrix-synapse";
    };
    age.secrets.synapse-mas-secret = {
      rekeyFile = ../../secrets/synapse-secrets/synapse-mas.age;
      owner = "matrix-synapse";
    };

    services.matrix-synapse = {
      enable = true;
      extraConfigFiles = [
        config.age.secrets.synapse-secret.path
        config.age.secrets.synapse-mas-secret.path
      ];
      settings = {
        server_name = domain;
        public_baseurl = "https://matrix.${domain}";
        listeners = [
          {
            port = 8008;
            bind_addresses = ["127.0.0.1"];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = ["client" "federation"];
                compress = true;
              }
            ];
          }
        ];
        experimental_features.msc4190_enabled = true;
        database = {
          name = "psycopg2";
          args = {
            database = "matrix-synapse";
            user = "matrix-synapse";
            host = "/run/postgresql";
          };
        };
      };
    };
    services.postgresql = {
      initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE DATABASE "matrix-synapse"
          WITH OWNER "matrix-synapse"
          ENCODING 'UTF8'
          LC_COLLATE 'C'
          LC_CTYPE 'C'
          TEMPLATE template0;
      '';
      ensureUsers = [
        {
          name = "matrix-synapse";
        }
      ];
    };

    services.nginx.virtualHosts = {
      "matrix.${domain}" = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8008";
          proxyWebsockets = true;
        };
      };
      "${domain}" = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations."= /.well-known/matrix/server" = {
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '{"m.server":"matrix.${domain}:443"}';
          '';
        };
        locations."= /.well-known/matrix/client" = {
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '{"m.homeserver":{"base_url":"https://matrix.${domain}"},"org.matrix.msc2965.authentication":{"issuer":"https://auth.matrix.${domain}/","account":"https://auth.matrix.${domain}/account"}}';
          '';
        };
      };
    };
    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/matrix-synapse";
        user = "matrix-synapse";
        group = "matrix-synapse";
        mode = "0700";
      }
    ];
  };
}
