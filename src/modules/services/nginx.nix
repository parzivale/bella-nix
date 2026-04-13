{
  flake.modules.nixos.nginx = {
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      commonHttpConfig = ''
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=86400' always;
      '';
    };

    networking.firewall = {
      allowedTCPPorts = [443];
      allowedUDPPorts = [443];
    };
  };
}
