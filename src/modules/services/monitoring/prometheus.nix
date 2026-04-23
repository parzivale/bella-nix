{
  self,
  lib,
  ...
}: {
  flake.modules.nixos.monitoring = {config, ...}: let
    tailscale = config.systemConstants.tailscale_dns;
    monitoredHosts = builtins.attrNames (
      lib.filterAttrs
      (_: {config, ...}: config.services.prometheus.exporters.node.enable)
      self.nixosConfigurations
    );
    prometheus_main_port = config.systemConstants.ports.prometheus.main;
    prometheus_export_port = config.systemConstants.ports.prometheus.exporter;
    scrapeTargets = map (h: "${h}.${tailscale}:${toString prometheus_export_port}") monitoredHosts;
  in {
    services.prometheus = {
      enable = true;
      port = prometheus_main_port;
      listenAddress = "127.0.0.1";
      retentionTime = "30d";
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{targets = scrapeTargets;}];
          relabel_configs = [
            {
              source_labels = ["__address__"];
              regex = "([^.]+)\\..*";
              target_label = "instance";
            }
          ];
        }
      ];
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
