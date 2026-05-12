{self, ...}: {
  flake.modules.nixos.router = {
    config,
    lib,
    ...
  }: {
    imports = with self.modules.nixos; [
      nginx
      acme
    ];

    services.nginx.virtualHosts = lib.mkMerge (
      lib.mapAttrsToList (
        _: nixosCfg:
          nixosCfg.config.services.nginx.virtualHosts
      ) (builtins.removeAttrs self.nixosConfigurations [config.networking.hostName])
    );
  };
}
