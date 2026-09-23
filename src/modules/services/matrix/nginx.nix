{ inputs, ... }:
{
  flake.modules.nixos.matrix =
    { config, ... }:
    let
      domain = config.constants.domain;
      mas_domain = config.constants.subDomains.mas;
      matrix_domain = config.constants.subDomains.matrix;
      mas_web_port = config.constants.ports.matrix.mas.web;
      matrix_main_port = config.constants.ports.matrix.main;
      backend = "${config.networking.hostName}.${config.constants.tailscale_dns}";
    in
    {
      imports = [ inputs.self.modules.nixos.nginx ];

      reverseProxy = {
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
