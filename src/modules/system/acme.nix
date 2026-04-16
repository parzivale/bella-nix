{
  flake.modules.nixos.acme = {config, ...}: let
    email = config.systemConstants.email;
  in {
    security.acme = {
      acceptTerms = true;
      defaults.email = email;
    };

    users.users.nginx.extraGroups = ["acme"];

    networking.firewall.allowedTCPPorts = [80];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/acme";
      }
    ];
  };
}
