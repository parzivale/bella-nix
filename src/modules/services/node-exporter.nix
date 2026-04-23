{
  flake.modules.nixos.node-exporter = {config, ...}: let
    prometheus_exporter_port = config.systemConstants.ports.prometheus.exporter;
  in {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = ["systemd"];
      port = prometheus_exporter_port;
      listenAddress = "127.0.0.1";
    };

    services.tailscale.serve.services.node-exporter = {
      endpoints = {
        "tcp:${prometheus_exporter_port}" = "http://127.0.0.1:${prometheus_exporter_port}";
      };
    };
  };
}
