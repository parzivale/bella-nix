{
  flake.modules.nixos.monitoring = {config, ...}: let
    loki_port = config.systemConstants.ports.loki;
  in {
    services.grafana.provision = {
      datasources.settings.datasources = [
        {
          name = "Loki";
          uid = "loki";
          type = "loki";
          url = "http://127.0.0.1:${toString loki_port}";
          access = "proxy";
        }
      ];

      dashboards.settings.providers = [
        {
          name = "community";
          options.path = ./json_dashboards;
        }
      ];
    };
  };
}
