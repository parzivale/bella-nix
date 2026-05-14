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

    # The ACME module chgrps the inner .well-known/acme-challenge/ dir but not the
    # outer acme-challenge/ webroot itself, so nginx can't traverse into it.
    systemd.tmpfiles.rules = [
      "d /var/lib/acme/acme-challenge 0750 acme nginx -"
      "z /var/lib/acme/acme-challenge 0750 acme nginx -"
    ];

    # Ensure nginx always waits for acme-setup to finish its privileged
    # chmod/chown before loading SSL certs. Without this, both services can
    # restart simultaneously during a generation switch, and nginx can race
    # the chown step, causing "Permission denied" on cert files.
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
