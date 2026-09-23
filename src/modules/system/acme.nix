{
  flake.modules.nixos.acme =
    { config, ... }:
    let
      email = config.constants.email;
    in
    {
      security.acme = {
        acceptTerms = true;
        defaults = {
          inherit email;
          group = "nginx";
        };
      };

      users.users.nginx.extraGroups = [ "acme" ];

      systemd.services.nginx = {
        after = [ "acme-setup.service" ];
        wants = [ "acme-setup.service" ];
      };

      networking.firewall.allowedTCPPorts = [ 80 ];

      state.preserve.directories = [
        {
          directory = "/var/lib/acme";
        }
      ];
    };
}
