{
  flake.modules.nixos.otel-collector = {
    config,
    pkgs,
    ...
  }: let
    tailscaleDomain = config.systemConstants.tailscale_dns;
    monitoringHost = config.systemConstants.monitoringHost;
    tempo_grpc_port = config.systemConstants.ports.tempo.grpc;
    tempo_http_port = config.systemConstants.ports.tempo.http;
  in {
    services.opentelemetry-collector = {
      enable = true;
      settings = {
        receivers.otlp.protocols = {
          grpc.endpoint = "127.0.0.1:${toString tempo_grpc_port}";
          http.endpoint = "127.0.0.1:${toString tempo_http_port}";
        };

        exporters.otlp = {
          endpoint = "${monitoringHost}.${tailscaleDomain}:${toString tempo_grpc_port}";
          tls.insecure = true;
        };

        service.pipelines.traces = {
          receivers = ["otlp"];
          exporters = ["otlp"];
        };
      };
    };
  };
}
