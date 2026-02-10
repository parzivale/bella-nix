{
  config,
  lib,
  ...
}: {
  systemd.services = {
    tailscaled-autoconnect.after = ["agenix-install-secrets.service"];
    tailscaled-autoconnect.requires = ["agenix-install-secrets.service"];
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
