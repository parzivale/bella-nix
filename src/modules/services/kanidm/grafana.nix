{
  flake.modules.nixos.kanidm =
    { config, ... }:
    let
      grafana_domain = config.systemConstants.subDomains.grafana;
    in
    {
      age.secrets.kanidm-grafana-client-secret = {
        rekeyFile = ../../../secrets/kanidm/grafana-client-secret.age;
        owner = "kanidm";
      };

      services.kanidm.provision.systems.oauth2."grafana" = {
        displayName = "Grafana";
        originUrl = "https://${grafana_domain}/login/generic_oauth";
        originLanding = "https://${grafana_domain}";
        basicSecretFile = config.age.secrets.kanidm-grafana-client-secret.path;
        preferShortUsername = true;
        scopeMaps."admins" = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
      };
    };
}
