{
  flake.modules.nixos.monitoring = {config, ...}: let
    loki_port = config.systemConstants.ports.loki;
  in {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = loki_port;
          http_listen_address = "127.0.0.1";
        };
        common = {
          instance_addr = "127.0.0.1";
          path_prefix = "/var/lib/loki";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
        };
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
    };

    services.tailscale.serve.services.loki = {
      endpoints = {
        "tcp:${loki_port}" = "http://127.0.0.1:${loki_port}";
      };
    };

    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "Loki";
        type = "loki";
        url = "http://127.0.0.1:${toString loki_port}";
      }
    ];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/loki";
        user = "loki";
        group = "loki";
      }
    ];
  };
}
