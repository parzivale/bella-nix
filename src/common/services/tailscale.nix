{
  config,
  lib,
  ...
}: {
  services.tailscale = {
    enable = lib.mkDefault true;
    authKeyFile = config.age.secrets.tailscale_token.path;
    authKeyParameters = {
      preauthorized = true;
    };
    disableTaildrop = true;
  };
}
