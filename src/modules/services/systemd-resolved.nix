{
  flake.modules.nixos.systemd-resolved = {
    services.resolved = {
      enable = true;
      settings.Resolve.MulticastDNS = "no";
    };
  };
}
