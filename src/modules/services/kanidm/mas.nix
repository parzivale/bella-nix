{
  flake.modules.nixos.kanidm = {config, ...}: let
    mas_domain = config.systemConstants.subDomains.mas;
    mas_provider_id = "01KRHPHYTTHPJT2E1FCJZSZ4SV";
  in {
    age.secrets.kanidm-mas-client-secret = {
      rekeyFile = ../../../secrets/kanidm/mas-client-secret.age;
      owner = "kanidm";
    };

    services.kanidm.provision.systems.oauth2."mas" = {
      displayName = "Matrix Authentication Service";
      originUrl = "https://${mas_domain}/upstream/callback/${mas_provider_id}";
      originLanding = "https://${mas_domain}";
      basicSecretFile = config.age.secrets.kanidm-mas-client-secret.path;
      preferShortUsername = true;
      scopeMaps."admins" = ["openid" "profile" "email"];
    };
  };
}
