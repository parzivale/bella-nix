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
          nixosCfg.config.reverseProxy
      ) self.nixosConfigurations
    );
  };
}
