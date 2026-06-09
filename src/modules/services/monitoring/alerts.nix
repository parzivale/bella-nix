{
  flake.modules.nixos.monitoring = _: {
    services.grafana.provision.alerting.rules.settings = {
      apiVersion = 1;
      groups = [
        {
          orgId = 1;
          name = "service_health";
          folder = "Alerts";
          interval = "1m";
          rules = [
            {
              uid = "systemd-service-failed";
              title = "SystemdServiceFailed";
              condition = "A";
              data = [
                {
                  refId = "A";
                  relativeTimeRange = {
                    from = 600;
                    to = 0;
                  };
                  datasourceUid = "prometheus";
                  model = {
                    expr = "node_systemd_unit_state{state=\"failed\"} == 1";
                    instant = true;
                    refId = "A";
                  };
                }
              ];
              noDataState = "OK";
              execErrState = "Error";
              for = "2m";
              labels = {
                severity = "critical";
              };
              annotations = {
                summary = "{{ $labels.name }} has failed";
                description = "Systemd unit {{ $labels.name }} has been in a failed state for more than 2 minutes";
              };
              isPaused = false;
            }
          ];
        }
      ];
    };
  };
}
