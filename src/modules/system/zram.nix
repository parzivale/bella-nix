{
  flake.modules.nixos.zram = {
    zramSwap.enable = true;
    boot.kernel.sysctl."vm.swappiness" = 180;
  };
}
