{self, ...}: {
  flake.modules.nixos.synapse = {
    imports = [
      self.modules.nixos.cloudflared
      ({config, ...}: {
        services.matrix-synapse.extraConfigFiles = [config.age.secrets.synapse-secret.path];
      })
    ];

    services.cloudflared.tunnels."parzivale".ingress = {
      "matrix.parzivale.dev" = "http://localhost:8008";
      "parzivale.dev" = "http://localhost:8080";
    };

    services.matrix-synapse = {
      enable = true;
      settings = {
        server_name = "parzivale.dev";
        public_baseurl = "https://matrix.parzivale.dev";

        listeners = [
          {
            port = 8008;
            bind_addresses = ["127.0.0.1"];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [{names = ["client" "federation"]; compress = true;}];
          }
        ];

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
      enable = true;
      ensureDatabases = ["matrix-synapse"];
      ensureUsers = [{name = "matrix-synapse"; ensureDBOwnership = true;}];
    };

    # Serves Matrix well-known files so user IDs are @user:parzivale.dev
    services.nginx = {
      enable = true;
      virtualHosts."matrix-well-known" = {
        listen = [{addr = "127.0.0.1"; port = 8080; ssl = false;}];
        locations."= /.well-known/matrix/server" = {
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '{"m.server":"matrix.parzivale.dev:443"}';
          '';
        };
        locations."= /.well-known/matrix/client" = {
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '{"m.homeserver":{"base_url":"https://matrix.parzivale.dev"},"m.identity_server":{"base_url":"https://vector.im"}}';
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
