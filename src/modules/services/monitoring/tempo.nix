{
  flake.modules.nixos.monitoring = {config, ...}: let
    tempo_main_port = config.systemConstants.ports.tempo.main;
    tempo_grpc_port = config.systemConstants.ports.tempo.grpc;
    tempo_http_port = config.systemConstants.ports.tempo.http;
  in {
    services.tempo = {
      enable = true;
      settings = {
        server.http_listen_port = tempo_main_port;
        distributor.receivers.otlp.protocols = {
          grpc.endpoint = "127.0.0.1:${toString tempo_grpc_port}";
          http.endpoint = "127.0.0.1:${toString tempo_http_port}";
        };
        ingester.max_block_duration = "5m";
        compactor.compaction.block_retention = "48h";
        storage.trace = {
          backend = "local";
          local.path = "/var/lib/private/tempo/traces";
          wal.path = "/var/lib/private/tempo/wal";
        };
      };
    };

    services.tailscale.serve.services.tempo = {
      endpoints = {
        "tcp:${tempo_main_port}" = "http://127.0.0.1:${tempo_main_port}";
      };
    };

    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "Tempo";
        type = "tempo";
        url = "http://127.0.0.1:${toString tempo_main_port}";
      }
    ];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/private/tempo";
        user = "tempo";
        group = "tempo";
      }
    ];
  };
}
