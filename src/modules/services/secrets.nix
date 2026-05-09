{
  flake.modules.nixos.secrets = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
    cacheDir = "/tmp/agenix-rekey.${toString config.systemConstants.uid}";
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
      "d ${cacheDir} 1777 ${user} users"
    ];

    age = {
      rekey = {
        requiredSystemFeatures = ["yubikey"];
        inherit cacheDir;
        masterIdentities = [../../secrets/yubikey/yubikey_identity_usbc.pub ../../secrets/yubikey/yubikey_identity_usba.pub];
        agePlugins = [pkgs.age-plugin-fido2-hmac];

        storageMode = "derivation";
      };
    };
  };
}
