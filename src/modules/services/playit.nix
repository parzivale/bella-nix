{inputs, ...}: {
  flake.modules.nixos.playit = {config, ...}: {
    imports = [inputs.playit-nixos-module.nixosModules.default];

    age.secrets.playit-secret.rekeyFile = ../../secrets/playit/playit-secret.age;

    services.playit = {
      enable = true;
      secretPath = config.age.secrets.playit-secret.path;
    };
  };
}
