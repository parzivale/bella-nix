{
  flake.modules.nixos.kanidm = {config, ...}: let
    kanidm_domain = config.systemConstants.subDomains.kanidm;
    kanidm_port = config.systemConstants.ports.kanidm;
    base_domain = config.systemConstants.domain;
    username = config.systemConstants.username;
    email = config.systemConstants.email;
  in {
    age.secrets.kanidm-idm-admin-password = {
      rekeyFile = ../../../secrets/kanidm/idm-admin-password.age;
      owner = "kanidm";
    };

    services.kanidm = {
      enableServer = true;
      serverSettings = {
        domain = base_domain;
        origin = "https://${kanidm_domain}";
        bindaddress = "0.0.0.0:${toString kanidm_port}";
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
        proxyPass = "http://${config.networking.hostName}.${config.systemConstants.tailscale_dns}:${toString kanidm_port}";
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
