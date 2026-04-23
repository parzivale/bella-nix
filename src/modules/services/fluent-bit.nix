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
              tag = "host.${hostname}";
              systemd_filter = "_SYSTEMD_UNIT=*";
            }
          ];

          outputs = [
            {
              name = "loki";
              match = "*";
              host = "${monitoringHost}.${tailscaleDomain}";
              port = loki_port;
            }
          ];
        };
      };
    };
  };
}
