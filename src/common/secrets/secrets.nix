{vars, ...}: {
  nix.settings.extra-sandbox-paths = ["/tmp/agenix-rekey.\"${toString vars.uid}\""];
  age.rekey = {
    masterIdentities = [
      ./yubikey_identity.pub
    ];

    storageMode = "derivation";
  };

  age.secrets = {
    tailscale_token.rekeyFile = ./tailscale_key.age;
    deploy-key.rekeyFile = ./deploy-key.age;
  };
}
