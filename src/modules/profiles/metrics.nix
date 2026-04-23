{self, ...}: {
  flake.modules.nixos.metrics = {
    imports = with self.modules.nixos; [
      node-exporter
      fluent-bit
      otel-collector
    ];
  };
}
