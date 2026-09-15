{ ... }:
{
  flake.modules.nixos.tailscale =
    { config, ... }:
    {
      systemd.services = {
        tailscaled-autoconnect.after = [
          "agenix-install-secrets.service"
          "network-online.target"
        ];
        tailscaled-autoconnect.requires = [
          "agenix-install-secrets.service"
          "network-online.target"
        ];
        nginx.after = [ "tailscaled-autoconnect.service" ];
        nginx.wants = [ "tailscaled-autoconnect.service" ];
      };

      preservation.preserveAt."/persistent" = {
        directories = [
          {
            directory = "/var/lib/tailscale";
            mode = "0700";
          }
        ];
      };
      age.secrets.tailscale_token.rekeyFile = ../../secrets/master/tailscale/tailscale_key.age;

      services.tailscale = {
        enable = true;
        authKeyFile = config.age.secrets.tailscale_token.path;
        authKeyParameters = {
          preauthorized = true;
          ephemeral = false;
        };
        extraUpFlags = [ "--advertise-tags=tag:nixos" ];
        disableTaildrop = true;
      };
    };
}
