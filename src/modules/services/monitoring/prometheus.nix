{...}: {
  flake.modules.nixos.monitoring = {config, ...}: let
    prometheus_main_port = config.systemConstants.ports.prometheus.main;
  in {
    services.prometheus = {
      enable = true;
      port = prometheus_main_port;
      listenAddress = "127.0.0.1";
      retentionTime = "30d";
      extraFlags = ["--web.enable-remote-write-receiver"];
    };
    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://127.0.0.1:${toString prometheus_main_port}";
        access = "proxy";
        isDefault = true;
      }
    ];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/prometheus2";
        user = "prometheus";
        group = "prometheus";
      }
    ];
  };
}
