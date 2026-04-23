{
  flake.modules.nixos.grocy = {config, ...}: let
    grocy_domain = config.systemConstants.subDomains.grocy;
  in {
    services.grocy = {
      enable = true;
      hostName = "${grocy_domain}";
      settings.currency = "SEK";
    };

    services.phpfpm.pools.grocy.phpEnv.GROCY_BASE_URL = "https://${grocy_domain}/";

    services.nginx.virtualHosts."${grocy_domain}" = {
      quic = true;
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/grocy";
        user = "grocy";
        group = "nginx";
      }
    ];
  };
}
