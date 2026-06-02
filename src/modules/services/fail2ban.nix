{
  flake.modules.nixos.fail2ban = {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "10m";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
      jails = {
        # sshd jail is auto-enabled by NixOS when services.openssh.enable = true
        nginx-limit-req.settings = {
          maxretry = 50;
          findtime = "1m";
          # filter defines journalmatch; works with NixOS default systemd backend
        };
        nginx-botsearch.settings = {
          # access log is file-based, not captured in journald
          backend = "auto";
          logpath = "/var/log/nginx/access.log";
          maxretry = 2;
        };
      };
    };
  };
}
