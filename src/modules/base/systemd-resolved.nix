{
  flake.modules.nixos.systemd-resolved = {
    services.resolved.enable = true;
    services.nscd.enable = false;
  };
}
