{ inputs, ... }:
{
  flake.modules.nixos.kanidm =
    {
      config,
      pkgs,
      ...
    }:
    let
      kanidm_domain = config.constants.subDomains.kanidm;
      kanidm_port = config.constants.ports.kanidm;
      base_domain = config.constants.domain;
      username = config.constants.username;
      email = config.constants.email;
      certDir = "/var/lib/kanidm";
    in
    {
      imports = [
        inputs.self.modules.nixos.secrets
        inputs.self.modules.nixos.nginx
      ];

      age.secrets.kanidm-idm-admin-password = {
        rekeyFile = ../../../secrets/master/kanidm/idm-admin-password.age;
        owner = "kanidm";
      };

      systemd.services.kanidm-generate-cert = {
        wantedBy = [ "kanidm.service" ];
        before = [ "kanidm.service" ];
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

      # kanidm 1.10 reached end-of-life, and nixpkgs marks an EOL release insecure
      # rather than removing it - so the pin below stopped evaluating, and took
      # every other host with it through `router`'s fan-out over
      # `self.nixosConfigurations`.
      #
      # Permitted rather than bumped, because the bump is not a package change:
      # kanidmd migrates its database in place the first time a new minor starts,
      # with no path back short of restoring /var/lib/kanidm - so it wants
      # `kanidmd domain upgrade-check` and a backup run against the live server
      # before the version here moves. 1.10 -> 1.11 is the one step available
      # either way; kanidm refuses to skip a minor - and 1.11.2 is in nixpkgs and
      # evaluates against this provisioning config unchanged, so the database step
      # is the whole of what is left to do.
      #
      # The string carries the patch version because that is the package name, so
      # this goes stale on the next 1.10.x and says so rather than quietly
      # permitting something newer.
      permittedInsecurePackages = [ "kanidm-with-secret-provisioning-1.10.5" ];

      services.kanidm = {
        package = pkgs.kanidmWithSecretProvisioning_1_10;
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
          groups."admins".members = [ username ];
          persons.${username} = {
            displayName = username;
            mailAddresses = [ email ];
          };
        };
      };

      reverseProxy.${kanidm_domain} = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations."/" = {
          proxyPass = "https://${config.networking.hostName}.${config.constants.tailscale_dns}:${toString kanidm_port}";
          extraConfig = "proxy_ssl_verify off;";
          proxyWebsockets = true;
        };
      };

      state.preserve.directories = [
        {
          directory = "/var/lib/kanidm";
          user = "kanidm";
          group = "kanidm";
        }
      ];
    };
}
