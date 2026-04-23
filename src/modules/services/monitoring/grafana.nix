{
  flake.modules.nixos.monitoring = {config, ...}: let
    grafana_domain = config.systemConstants.subDomains.grafana;
    pocket-id_domain = config.systemConstants.subDomains.pocket-id;
    grafana_port = config.systemConstants.ports.grafana;
  in {
    age.secrets.grafana-secret-key = {
      rekeyFile = ../../../secrets/grafana/secret-key.age;
      owner = "grafana";
    };

    age.secrets.grafana-oauth-secret = {
      rekeyFile = ../../../secrets/grafana/oauth-client-secret.age;
      owner = "grafana";
    };

    services.grafana = {
      enable = true;
      settings = {
        security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        "auth.generic_oauth" = {
          enabled = true;
          name = "Pocket ID";
          client_id = "grafana";
          client_secret = "$__file{${config.age.secrets.grafana-oauth-secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://${pocket-id_domain}/authorize";
          token_url = "https://${pocket-id_domain}/api/oidc/token";
          api_url = "https://${pocket-id_domain}/api/oidc/userinfo";
          use_pkce = true;
          use_refresh_token = true;
          auto_login = true;
          role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
        };
        server = {
          domain = grafana_domain;
          root_url = "https://${grafana_domain}/";
          http_addr = "127.0.0.1";
          http_port = grafana_port;
        };
      };
      provision.enable = true;
    };

    services.nginx.virtualHosts.${grafana_domain} = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString grafana_port}";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/grafana";
        user = "grafana";
        group = "grafana";
      }
    ];
  };
}
