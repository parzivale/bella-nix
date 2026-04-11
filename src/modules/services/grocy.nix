{self, ...}: {
  flake.modules.nixos.grocy = {
    imports = [self.modules.nixos.cloudflared];

    services.cloudflared.tunnels."parzivale".ingress."grocy.parzivale.dev" = "http://localhost:80";

    services.grocy = {
      enable = true;
      hostName = "_";
      settings.currency = "SEK";
      nginx.enableSSL = false;
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/grocy";
        user = "grocy";
        group = "nginx";
        mode = "0750";
      }
    ];
  };
}
