{
  flake.modules.nixos.monitoring = {config, ...}: let
    grafana_domain = config.systemConstants.subDomains.grafana;
    kanidm_domain = config.systemConstants.subDomains.kanidm;
    grafana_port = config.systemConstants.ports.grafana;
    domain = config.systemConstants.domain;
  in {
    age.secrets.grafana-secret-key = {
      rekeyFile = ../../../secrets/grafana/secret-key.age;
      owner = "grafana";
    };

    age.secrets.grafana-kanidm-oauth-secret = {
      rekeyFile = ../../../secrets/kanidm/grafana-client-secret.age;
      owner = "grafana";
    };

    age.secrets.grafana-matrix-env = {
      rekeyFile = ../../../secrets/grafana/matrix-env.age;
      owner = "grafana";
    };

    services.grafana = {
      enable = true;
      settings = {
        security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        users.allow_sign_up = false;

        "auth.generic_oauth" = {
          allow_sign_up = false;
          enabled = true;
          name = "Kanidm";
          client_id = "grafana";
          client_secret = "$__file{${config.age.secrets.grafana-kanidm-oauth-secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://${kanidm_domain}/ui/oauth2";
          token_url = "https://${kanidm_domain}/oauth2/token";
          api_url = "https://${kanidm_domain}/oauth2/openid/grafana/userinfo";
          use_pkce = true;
          use_refresh_token = true;
          auto_login = true;
          login_attribute_path = "preferred_username";
          name_attribute_path = "name";
          role_attribute_path = "contains(groups[*], 'admins@${domain}') && 'Admin' || 'Viewer'";
          role_attribute_strict = false;
        };
        server = {
          domain = grafana_domain;
          root_url = "https://${grafana_domain}/";
          http_addr = "0.0.0.0";
          http_port = grafana_port;
        };
      };
      provision = {
        enable = true;
        alerting = {
          contactPoints.settings = {
            apiVersion = 1;
            contactPoints = [
              {
                orgId = 1;
                name = "Matrix";
                receivers = [
                  {
                    uid = "matrix-bot";
                    type = "matrix";
                    settings = {
                      url = "https://${config.systemConstants.subDomains.matrix}";
                      room_id = config.systemConstants.alertsRoomId;
                      token = "\${MATRIX_BOT_TOKEN}";
                    };
                  }
                ];
              }
            ];
          };
          policies.settings = {
            apiVersion = 1;
            policies = [
              {
                orgId = 1;
                receiver = "Matrix";
                group_by = ["grafana_folder" "alertname"];
                group_wait = "30s";
                group_interval = "5m";
                repeat_interval = "4h";
              }
            ];
          };
        };
      };
    };

    systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets.grafana-matrix-env.path;

    services.nginx.virtualHosts.${grafana_domain} = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://${config.networking.hostName}.${config.systemConstants.tailscale_dns}:${toString grafana_port}";
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
