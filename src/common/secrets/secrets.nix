{
  vars,
  config,
  lib,
  pkgs,
  ...
}: let
  user = vars.username;
  cacheDir = "/tmp/agenix-rekey.${toString vars.uid}";
in {
  systemd.services.agenix-install-secrets = {
    after = ["preservation.target"];
    requires = ["preservation.target"];
  };

  nix.settings.extra-sandbox-paths = [config.age.rekey.cacheDir];
  systemd.tmpfiles.rules = [
    "d ${cacheDir} 1777 ${user} ${user}"
  ];

  age = {
    rekey = {
      inherit cacheDir;
      masterIdentities = [
        ./yubikey_identity.pub
      ];

      agePlugins = [pkgs.age-plugin-fido2-hmac];

      storageMode = "derivation";
    };
    secrets = {
      tailscale_token.rekeyFile = ./tailscale_key.age;
      deploy-key.rekeyFile = ./deploy-key.age;
    };
  };

  home-manager.users.${user}.rekey.secrets = {
    github-key.rekeyFile = ./github-key.age;
  };
}
