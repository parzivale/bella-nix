{
  flake.modules.nixos.nginx = {pkgs, ...}: {
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      commonHttpConfig = ''
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=86400' always;
      '';
    };

    systemd.services.acme-setup.serviceConfig.ExecStartPost =
      "+${pkgs.coreutils}/bin/chown :nginx /var/lib/acme/acme-challenge";

    networking.firewall = {
      allowedTCPPorts = [443];
      allowedUDPPorts = [443];
    };
  };
}
