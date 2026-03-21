{
  flake.modules.nixos.earlyoom = {
    services.earlyoom.enable = true;
    systemd.oomd.enable = false;
  };
}
