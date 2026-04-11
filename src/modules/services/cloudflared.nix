{
  flake.modules.nixos.cloudflared = {config, ...}: {
    services.cloudflared = {
      enable = true;
      tunnels."parzivale" = {
        credentialsFile = config.age.secrets.cloudflare-tunnel-creds.path;
        default = "http_status:404";
      };
    };
  };
}
