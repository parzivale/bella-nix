{inputs, ...}: {
  flake.modules.nixos.secrets = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
    cacheDir = "/run/agenix-rekey.${toString config.systemConstants.uid}";
  in {
    home-manager.users.${user}.home = {
      packages = with pkgs; [
        age
        age-plugin-fido2-hmac
      ];
    };

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
        masterIdentities = [./src/secrets/yubikey/yubikey_identity.pub];
        agePlugins = [pkgs.age-plugin-fido2-hmac];

        storageMode = "derivation";
      };
      secrets = {
        tailscale_token.rekeyFile = ../../secrets/tailscale/tailscale_key.age;
        deploy-key.rekeyFile = ../../secrets/nix-deploy/deploy-key.age;
        github-key = {
          rekeyFile = ../../secrets/github/github-key.age;
          owner = user;
        };
      };
    };
  };
}
