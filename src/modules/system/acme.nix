{
  flake.modules.nixos.acme = {config, ...}: let
    email = config.systemConstants.email;
  in {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = email;
        group = "nginx";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/acme/acme-challenges 0750 acme nginx -"
    ];

    networking.firewall.allowedTCPPorts = [80];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/acme";
      }
    ];
  };
}
