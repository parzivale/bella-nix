{inputs, ...}: {
  flake.modules.nixos.playit = {config, ...}: {
    imports = [inputs.playit-nixos-module.nixosModules.default];

    services.playit = {
      enable = true;
      secretPath = config.age.secrets.playit-secret.path;
    };
  };
}
