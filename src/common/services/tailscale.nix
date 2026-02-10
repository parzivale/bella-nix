{
  config,
  lib,
  ...
}: {
  systemd.services = {
    tailscaled-autoconnect.after = ["agenix-install-secrets.service" "network-online.target"];
    tailscaled-autoconnect.requires = ["agenix-install-secrets.service" "network-online.target"];
  };

  services.tailscale = {
    enable = lib.mkDefault true;
    authKeyFile = config.age.secrets.tailscale_token.path;
    authKeyParameters = {
      preauthorized = true;
    };
    extraUpFlags = ["--advertise-tags=tag:nixos"];
    disableTaildrop = true;
  };
}
