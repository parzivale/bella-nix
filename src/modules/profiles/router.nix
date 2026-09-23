{ self, ... }:
{
  flake.modules.nixos.router =
    { lib, ... }:
    let
      allProxyDomains = lib.concatMap (nixosCfg: lib.attrNames (nixosCfg.config.reverseProxy or { })) (
        lib.attrValues self.nixosConfigurations
      );
      rateLimitConfig = lib.genAttrs allProxyDomains (_: {
        extraConfig = "limit_req zone=ratelimit burst=60 nodelay;";
      });
    in
    {
      imports = with self.modules.nixos; [
        nginx
        acme
        fail2ban
      ];

      services.nginx.virtualHosts = lib.mkMerge [
        (lib.mkMerge (
          # `reverseProxy` comes with nginx now rather than with every host, so
          # a host that runs no web server — or a finix host, which cannot
          # evaluate the nixos nginx module at all — simply advertises nothing.
          lib.mapAttrsToList (_: nixosCfg: nixosCfg.config.reverseProxy or { }) self.nixosConfigurations
        ))
        rateLimitConfig
      ];
    };
}
