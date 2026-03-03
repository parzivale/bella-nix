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

    preservation.preserveAt."/persistent" = {
      directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];
    };
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale_token.path;
      authKeyParameters = {
        preauthorized = true;
        ephemeral = false;
      };
      extraUpFlags = ["--advertise-tags=tag:nixos"];
      disableTaildrop = true;
    };
  };
}
