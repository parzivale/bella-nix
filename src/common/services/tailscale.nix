{
  config,
  lib,
  ...
}: {
  systemd.services.tailscaled-autoconnect.after = ["agenix-install-secrets.service"];

  services.tailscale = {
    enable = lib.mkDefault true;
    authKeyFile = config.age.secrets.tailscale_token.path;
    authKeyParameters = {
      preauthorized = true;
      ephemeral = false;
    };
    extraUpFlags = ["--advertise-tags=tag:nixos"];
    disableTaildrop = true;
  };
}
