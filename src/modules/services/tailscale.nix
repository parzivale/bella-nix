{
  flake.modules.nixos.tailscale = {
    config,
    lib,
    ...
  }: {
    systemd.services = {
      tailscaled-autoconnect.after = ["agenix-install-secrets.service" "network-online.target"];
      tailscaled-autoconnect.requires = ["agenix-install-secrets.service" "network-online.target"];
    };

    environment.persistence."/persist" = {
      directories = [
        "/var/lib/tailscale"
      ];
    };
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale_token.path;
      authKeyParameters = {
        preauthorized = true;
        ephermeral = false;
      };
      extraUpFlags = ["--advertise-tags=tag:nixos"];
      disableTaildrop = true;
    };
  };
}
