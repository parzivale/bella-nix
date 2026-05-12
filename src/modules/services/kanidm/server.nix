{
  flake.modules.nixos.kanidm = {
    config,
    pkgs,
    ...
  }: let
    kanidm_domain = config.systemConstants.subDomains.kanidm;
    kanidm_port = config.systemConstants.ports.kanidm;
    base_domain = config.systemConstants.domain;
    username = config.systemConstants.username;
    email = config.systemConstants.email;
    certDir = "/var/lib/kanidm";
  in {
    age.secrets.kanidm-idm-admin-password = {
      rekeyFile = ../../../secrets/kanidm/idm-admin-password.age;
      owner = "kanidm";
    };

    systemd.services.kanidm-generate-cert = {
      wantedBy = ["kanidm.service"];
      before = ["kanidm.service"];
      unitConfig.ConditionPathExists = "!${certDir}/tls.crt";
      serviceConfig = {
        Type = "oneshot";
        User = "kanidm";
        ExecStart = pkgs.writeShellScript "kanidm-gen-cert" ''
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
            -keyout ${certDir}/tls.key \
            -out ${certDir}/tls.crt \
            -not_after 99991231235959Z -nodes \
            -subj "/CN=${config.networking.hostName}"
        '';
      };
    };

    services.kanidm = {
      package = pkgs.kanidmWithSecretProvisioning_1_9;
      server = {
        enable = true;
        settings = {
          domain = base_domain;
          origin = "https://${kanidm_domain}";
          bindaddress = "0.0.0.0:${toString kanidm_port}";
          tls_chain = "${certDir}/tls.crt";
          tls_key = "${certDir}/tls.key";
        };
      };
      provision = {
        enable = true;
        idmAdminPasswordFile = config.age.secrets.kanidm-idm-admin-password.path;
        groups."admins".members = [username];
        persons.${username} = {
          displayName = username;
          mailAddresses = [email];
        };
      };
    };

    services.nginx.virtualHosts.${kanidm_domain} = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      locations."/" = {
        proxyPass = "https://${config.networking.hostName}.${config.systemConstants.tailscale_dns}:${toString kanidm_port}";
        extraConfig = "proxy_ssl_verify off;";
        proxyWebsockets = true;
      };
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/kanidm";
        user = "kanidm";
        group = "kanidm";
      }
    ];
  };
}
