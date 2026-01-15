{vars, ...}: {
  nix.settings.extra-sandbox-paths = ["/tmp/agenix-rekey.${toString vars.uid}"];
  age.rekey = {
    masterIdentities = [
      ./yubikey_identity.pub
    ];

    storageMode = "derivation";
  };

  age.secrets = {
    user-password.rekeyFile = ./user-password.age;
  };
}
