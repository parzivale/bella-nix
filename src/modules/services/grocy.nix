{
  flake.modules.nixos.grocy = {
    config,
    pkgs,
    ...
  }: {
    services.grocy = {
      enable = true;
      hostName = "_";
      settings = {
        currency = "SEK";
      };
      nginx.enableSSL = false;
    };

    systemd.services.tailscale-funnel-grocy = {
      description = "Tailscale Funnel for Grocy";
      after = ["tailscaled-autoconnect.service" "network-online.target"];
      wants = ["tailscaled-autoconnect.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale funnel --bg --https=443 http://localhost:80";
        ExecStop = "${pkgs.tailscale}/bin/tailscale funnel --bg --https=443 http://localhost:80 off";
      };
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
