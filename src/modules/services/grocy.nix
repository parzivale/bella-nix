{
  flake.modules.nixos.grocy = {config, ...}: let
    domain = config.systemConstants.domain;
  in {
    services.grocy = {
      enable = true;
      hostName = "grocy.${domain}";
      settings.currency = "SEK";
    };

    services.nginx.virtualHosts."grocy.${domain}" = {
      quic = true;
    };
  };
}
