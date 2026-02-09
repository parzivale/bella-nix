{
  vars,
  config,
  lib,
  ...
}: let
  cacheDir = "/tmp/agenix-rekey.${toString vars.uid}";
in {
  nix.settings.extra-sandbox-paths = [config.age.rekey.cacheDir];
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
