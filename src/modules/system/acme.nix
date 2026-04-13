{
  flake.modules.nixos.acme = {config, ...}: let
    email = config.systemConstants.email;
  in {
    security.acme = {
      acceptTerms = true;
      defaults.email = email;
    };

    networking.firewall.allowedTCPPorts = [80];

    preservation.preserveAt."/persistent".directories = [
      "/var/lib/acme"
    ];
  };
}
