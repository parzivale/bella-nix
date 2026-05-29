{self, ...}: {
  flake.modules.nixos.router = {
    lib,
    ...
  }: let
    allProxyDomains = lib.concatMap
      (nixosCfg: lib.attrNames nixosCfg.config.reverseProxy)
      (lib.attrValues self.nixosConfigurations);
    rateLimitConfig = lib.genAttrs allProxyDomains (_: {
      extraConfig = "limit_req zone=ratelimit burst=20 nodelay;";
    });
  in {
    imports = with self.modules.nixos; [
      nginx
      acme
      fail2ban
    ];

    services.nginx.virtualHosts = lib.mkMerge [
      (lib.mkMerge (
        lib.mapAttrsToList (
          _: nixosCfg:
            nixosCfg.config.reverseProxy
        ) self.nixosConfigurations
      ))
      rateLimitConfig
    ];
  };
}
