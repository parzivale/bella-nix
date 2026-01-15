{vars, ...}: {
  nix.settings.extra-sandbox-paths = ["/tmp/agenix-rekey.${toString vars.uid}"];
  age.rekey = {
    masterIdentities = [
      ./yubikey_identity.pub
    ];

    storageMode = "derivation";
  };

  age.secrets = {
    user_password.rekeyFile = ./user_password.age;
    bootstrap_key.rekeyFile = ./bootstrap_key.age;
  };
}
