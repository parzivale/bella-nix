{
  flake.modules.nixos.matrix =
    {
      config,
      pkgs,
      ...
    }:
    let
      domain = config.systemConstants.domain;
      matrix_domain = config.systemConstants.subDomains.matrix;
      mas_domain = config.systemConstants.subDomains.mas;
      matrix_main_port = config.systemConstants.ports.matrix.main;
      mas_web_port = config.systemConstants.ports.matrix.mas.web;
    in
    {
      age.secrets.synapse-secret = {
        rekeyFile = ../../../secrets/synapse-secrets/synapse-secrets.age;
        owner = "matrix-synapse";
      };
      age.secrets.synapse-mas-secret = {
        rekeyFile = ../../../secrets/synapse-secrets/synapse-mas.age;
        owner = "matrix-synapse";
      };

      services.matrix-synapse = {
        enable = true;
        extraConfigFiles = [ config.age.secrets.synapse-secret.path ];
        settings = {
          server_name = domain;
          public_baseurl = "https://${matrix_domain}";
          listeners = [
            {
              port = matrix_main_port;
              bind_addresses = [ "0.0.0.0" ];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = true;
                }
              ];
            }
          ];
          experimental_features.msc4190_enabled = true;
          matrix_authentication_service = {
            enabled = true;
            endpoint = "http://127.0.0.1:${toString mas_web_port}";
            account_management_url = "https://${mas_domain}/account";
            secret_path = config.age.secrets.synapse-mas-secret.path;
          };
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
        ensureUsers = [ { name = "matrix-synapse"; } ];
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
