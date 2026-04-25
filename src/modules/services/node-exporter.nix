{
  flake.modules.nixos.node-exporter = {config, ...}: let
    prometheus_exporter_port = config.systemConstants.ports.prometheus.exporter;
  in {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = ["systemd"];
      port = prometheus_exporter_port;
      listenAddress = "0.0.0.0";
    };
  };
}
