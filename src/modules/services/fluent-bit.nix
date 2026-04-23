{
  flake.modules.nixos.fluent-bit = {config, ...}: let
    tailscaleDomain = config.systemConstants.tailscale_dns;
    monitoringHost = config.systemConstants.monitoringHost;
    loki_port = config.systemConstants.ports.loki;
    hostname = config.networking.hostName;
  in {
    services.fluent-bit = {
      enable = true;
      settings = {
        service = {
          flush = 5;
          log_level = "info";
        };

        pipeline = {
          inputs = [
            {
              name = "systemd";
              tag = "journal.*";
              read_from_tail = "on";
            }
          ];

          outputs = [
            {
              name = "loki";
              match = "journal.*";
              host = "${monitoringHost}.${tailscaleDomain}";
              port = loki_port;
              labels = "job=systemd-journal,host=${hostname}";
              label_keys = "UNIT";
            }
          ];
        };
      };
    };
  };
}
