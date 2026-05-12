{
  flake.modules.nixos.matrix = {config, ...}: let
    domain = config.systemConstants.domain;
    mas_domain = config.systemConstants.subDomains.mas;
    matrix_domain = config.systemConstants.subDomains.matrix;
    mas_web_port = config.systemConstants.ports.matrix.mas.web;
    matrix_main_port = config.systemConstants.ports.matrix.main;
    backend = "${config.networking.hostName}.${config.systemConstants.tailscale_dns}";
  in {
    services.nginx.virtualHosts = {
      ${mas_domain} = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations."/" = {
          proxyPass = "http://${backend}:${toString mas_web_port}";
          proxyWebsockets = true;
        };
      };

      ${matrix_domain} = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations = {
          "/" = {
            proxyPass = "http://${backend}:${toString matrix_main_port}";
            proxyWebsockets = true;
          };
          "= /.well-known/matrix/client" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.homeserver":{"base_url":"https://${matrix_domain}"},"org.matrix.msc2965.authentication":{"issuer":"https://${mas_domain}/","account":"https://${mas_domain}/account"}}';
            '';
          };
          "~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
            proxyPass = "http://${backend}:${toString mas_web_port}";
            proxyWebsockets = true;
          };
        };
      };

      ${domain} = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations = {
          "= /.well-known/matrix/server" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.server":"${matrix_domain}:443"}';
            '';
          };
          "= /.well-known/matrix/client" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{"m.homeserver":{"base_url":"https://${matrix_domain}"}}';
            '';
          };
        };
      };
    };
  };
}
