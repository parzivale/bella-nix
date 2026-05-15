{...}: {
  flake.modules.nixos.monitoring = {config, ...}: let
    prometheus_main_port = config.systemConstants.ports.prometheus.main;
  in {
    services.prometheus = {
      enable = true;
      port = prometheus_main_port;
      listenAddress = "0.0.0.0";
      retentionTime = "30d";
      extraFlags = ["--web.enable-remote-write-receiver"];
    };
    services.grafana.provision.datasources.settings = {
      deleteDatasources = [
        {name = "Prometheus"; orgId = 1;}
        {name = "Loki"; orgId = 1;}
      ];
      datasources = [
        {
          uid = "prometheus";
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString prometheus_main_port}";
          access = "proxy";
          isDefault = true;
          jsonData.timeInterval = "60s";
        }
      ];
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/prometheus2";
        user = "prometheus";
        group = "prometheus";
      }
    ];
  };
}
