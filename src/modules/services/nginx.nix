{
  flake.modules.nixos.nginx = {config, ...}: {
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      commonHttpConfig = ''
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=86400' always;
      '';
      virtualHosts."localhost" = {
        listen = [{ addr = "127.0.0.1"; port = 81; }];
        locations."/stub_status".extraConfig = "stub_status;";
      };
    };

    services.prometheus.exporters.nginx = {
      enable = true;
      scrapeUri = "http://127.0.0.1:81/stub_status";
    };

    environment.etc."alloy/nginx.alloy".text = ''
      prometheus.scrape "nginx" {
        targets = [{"__address__" = "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}"}]
        forward_to = [prometheus.remote_write.monitoring.receiver]
      }
    '';

    networking.firewall = {
      allowedTCPPorts = [443];
      allowedUDPPorts = [443];
    };
  };
}
