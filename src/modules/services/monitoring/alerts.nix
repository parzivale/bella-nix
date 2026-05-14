{
  flake.modules.nixos.monitoring = {...}: {
    services.prometheus.rules = [
      ''
        groups:
          - name: service_health
            interval: 1m
            rules:
              - alert: SystemdServiceFailed
                expr: node_systemd_unit_state{state="failed"} == 1
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "{{ $labels.name }} has failed"
                  description: "Systemd unit {{ $labels.name }} has been in a failed state for more than 2 minutes"
      ''
    ];
  };
}
