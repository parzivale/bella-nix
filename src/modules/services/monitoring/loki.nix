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
          http_listen_address = "0.0.0.0";
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

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/loki";
        user = "loki";
        group = "loki";
      }
    ];
  };
}
