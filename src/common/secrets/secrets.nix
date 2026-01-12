{config, ...}: {
  age.rekey = {
    masterIdentities = [
      ./mykey.pub
    ];

    storageMode = "local";
    localStorageDir = ./. + "/rekeyed/${config.networking.hostName}";
  };

  age.secrets = {
    user-password.rekeyFile = ./user-password.age;
  };
}
