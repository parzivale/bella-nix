{
  vars,
  config,
  pkgs,
  ...
}: let
  user = vars.username;
  cacheDir = "/tmp/agenix-rekey.${toString vars.uid}";
in {
  flake.modules.bella.secrets = {
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
          ../secrets/yubikey/yubikey_identity.pub
        ];
        agePlugins = [pkgs.age-plugin-fido2-hmac];

        storageMode = "derivation";
      };
      secrets = {
        tailscale_token.rekeyFile = ../secrets/tailscale_key.age;
        deploy-key.rekeyFile = ../secrets/deploy-key.age;
        github-key = {
          rekeyFile = ../secrets/github-key.age;
          owner = user;
        };
      };
    };
  };
}
