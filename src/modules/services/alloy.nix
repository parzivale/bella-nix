{
  flake.modules.nixos.alloy = {
    config,
    pkgs,
    ...
  }: let
    tailscaleDomain = config.systemConstants.tailscale_dns;
    monitoringHost = config.systemConstants.monitoringHost;
    loki_port = config.systemConstants.ports.loki;
    prometheus_port = config.systemConstants.ports.prometheus.main;
    hostname = config.networking.hostName;
  in {
    services.alloy = {
      enable = true;
      configPath = pkgs.writeText "config.alloy" ''
        prometheus.exporter.unix "node" {}

        prometheus.scrape "node" {
          targets    = prometheus.exporter.unix.node.targets
          forward_to = [prometheus.remote_write.monitoring.receiver]
        }

        prometheus.remote_write "monitoring" {
          endpoint {
            url = "http://${monitoringHost}.${tailscaleDomain}:${toString prometheus_port}/api/v1/write"
          }
        }

        loki.source.journal "journal" {
          forward_to = [loki.write.monitoring.receiver]
          labels = {
            job  = "alloy",
            host = "${hostname}",
          }
        }

        loki.write "monitoring" {
          endpoint {
            url = "http://${monitoringHost}.${tailscaleDomain}:${toString loki_port}/loki/api/v1/push"
          }
        }
      '';
    };
  };
}
