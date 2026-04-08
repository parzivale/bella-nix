{
  flake.modules.nixos.swapfile = {
    swapDevices = [
      {
        device = "/persistent/swapfile";
        size = 16384; # 16GB
        priority = 1; # lower than zram (default 100) so it's only used as backup
      }
    ];
  };
}
