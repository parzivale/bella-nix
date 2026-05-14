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

    users.users.nginx.extraGroups = ["acme"];

    systemd.services.nginx = {
      after = ["acme-setup.service"];
      wants = ["acme-setup.service"];
    };

    networking.firewall.allowedTCPPorts = [80];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/acme";
      }
    ];
  };
}
