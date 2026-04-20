{
  flake.modules.nixos.grocy = {config, ...}: let
    domain = config.systemConstants.domain;
  in {
    services.grocy = {
      enable = true;
      hostName = "grocy.${domain}";
      settings.currency = "SEK";
    };

    services.phpfpm.pools.grocy.phpEnv.GROCY_BASE_URL = "https://grocy.${domain}/";

    services.nginx.virtualHosts."grocy.${domain}" = {
      quic = true;
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/grocy";
      }
    ];
  };
}
