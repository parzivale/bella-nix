{
  flake.modules.nixos.systemd-resolved = {
    services.resolved.enable = true;
  };
}
