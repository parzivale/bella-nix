{
  vars,
  config,
  lib,
  ...
}: let
  user = vars.username;
  cacheDir = "/tmp/agenix-rekey.${toString vars.uid}";
in {
  nix.settings.extra-sandbox-paths = [config.age.rekey.cacheDir];
  systemd.tmpfiles.rules = [
    "d ${cacheDir} 1777 ${user} ${user}"
  ];
  age.rekey = {
    inherit cacheDir;
    masterIdentities = [
      ./yubikey_identity.pub
    ];

    storageMode = "derivation";
  };

  age.secrets = {
    tailscale_token.rekeyFile = ./tailscale_key.age;
    deploy-key.rekeyFile = ./deploy-key.age;
    github-key.rekeyFile = ./github-key.age;
  };
}
