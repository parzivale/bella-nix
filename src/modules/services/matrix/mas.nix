{
  flake.modules.nixos.matrix = {
    config,
    pkgs,
    lib,
    ...
  }: let
    inherit (lib) filterAttrs mapAttrs filter isAttrs isList concatMapStringsSep;
    domain = config.systemConstants.domain;
    mas_domain = config.systemConstants.subDomains.mas;
    matrix_domain = config.systemConstants.subDomains.matrix;
    pocket-id_domain = config.systemConstants.subDomains.pocket-id;
    mas_web_port = config.systemConstants.ports.matrix.mas.web;
    mas_internal_port = config.systemConstants.ports.matrix.mas.internal;
    matrix_main_port = config.systemConstants.ports.matrix.main;
    mas = pkgs.matrix-authentication-service;

    format = pkgs.formats.yaml {};
    filterRecursiveNull = o:
      if isAttrs o
      then mapAttrs (_: v: filterRecursiveNull v) (filterAttrs (_: v: v != null) o)
      else if isList o
      then map filterRecursiveNull (filter (v: v != null) o)
      else o;

    settings = {
      http = {
        public_base = "https://${mas_domain}/";
        trusted_proxies = ["127.0.0.1/8" "::1/128"];
        listeners = [
          {
            name = "web";
            resources = [
              {name = "discovery";}
              {name = "human";}
              {name = "oauth";}
              {name = "compat";}
              {name = "graphql";}
              {name = "assets";}
            ];
            binds = [
              {
                host = "127.0.0.1";
                port = mas_web_port;
              }
            ];
            proxy_protocol = false;
          }
          {
            name = "internal";
            resources = [{name = "health";}];
            binds = [
              {
                host = "127.0.0.1";
                port = mas_internal_port;
              }
            ];
            proxy_protocol = false;
          }
        ];
      };
      database.uri = "postgresql:///matrix-authentication-service?host=/run/postgresql";
      matrix = {
        homeserver = domain;
        endpoint = "http://127.0.0.1:${toString matrix_main_port}";
      };
      passwords.enabled = false;
      account.management_url = "https:/${mas_domain}/account";
      upstream_oauth2.providers = [
        {
          id = "01KP9M2FDVT46D0CXQJAR9ZGG2";
          issuer = pocket-id_domain;
          human_name = "Pocket ID";
          client_id = "mas";
          client_secret_file = config.age.secrets.mas-oauth-client-secret.path;
          token_endpoint_auth_method = "client_secret_basic";
          scope = "openid profile email";
          claims_imports = {
            localpart = {
              action = "require";
              template = "{{ user.preferred_username }}";
            };
            displayname = {
              action = "suggest";
              template = "{{ user.name }}";
            };
            email = {
              action = "suggest";
              template = "{{ user.email }}";
            };
          };
        }
      ];
    };

    configFile = format.generate "mas-config.yaml" (filterRecursiveNull settings);
    extraConfigFiles = [config.age.secrets.mas-config.path];
    configArgs = concatMapStringsSep " " (x: "--config ${x}") ([configFile] ++ extraConfigFiles);
  in {
    age.secrets.mas-config = {
      rekeyFile = ../../../secrets/mas/mas-config.age;
      owner = "matrix-authentication-service";
    };
    age.secrets.mas-oauth-client-secret = {
      rekeyFile = ../../../secrets/mas/mas-oauth-client-secret.age;
      owner = "matrix-authentication-service";
    };

    systemd.services.matrix-authentication-service = {
      description = "Matrix Authentication Service";
      after = ["network.target" "postgresql.service" "preservation.target"];
      requires = ["postgresql.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = "matrix-authentication-service";
        Group = "matrix-authentication-service";
        StateDirectory = "matrix-authentication-service";
        ExecStartPre = [
          ("+"
            + (pkgs.writeShellScript "mas-check-config" ''
              ${lib.getExe mas} config check ${configArgs}
            ''))
        ];
        ExecStart = "${lib.getExe mas} ${configArgs} server";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    users.users.matrix-authentication-service = {
      isSystemUser = true;
      group = "matrix-authentication-service";
    };
    users.groups.matrix-authentication-service = {};

    services.postgresql = {
      ensureDatabases = ["matrix-authentication-service"];
      ensureUsers = [
        {
          name = "matrix-authentication-service";
          ensureDBOwnership = true;
        }
      ];
    };

    services.nginx.virtualHosts."${mas_domain}" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString mas_web_port}";
        proxyWebsockets = true;
      };
    };

    services.nginx.virtualHosts."${matrix_domain}" = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."= /.well-known/matrix/client" = {
        extraConfig = lib.mkForce ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '{"m.homeserver":{"base_url":"https://${matrix_domain}"},"org.matrix.msc2965.authentication":{"issuer":"https://${mas_domain}/","account":"https://${mas_domain}/account"}}';
        '';
      };
      locations."~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
        proxyPass = "http://127.0.0.1:${toString mas_web_port}";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/matrix-authentication-service";}
    ];
  };
}
