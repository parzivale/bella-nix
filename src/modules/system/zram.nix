{
  flake.modules.nixos.zram = {
    zramSwap.enable = true;

    # zram is fast enough that swapping early beats reclaiming; both classes
    # declare it at the same path.
    boot.kernel.sysctl."vm.swappiness" = 180;
  };

  flake.modules.finix.zram =
    { modules, ... }:
    {
      imports = [ modules.zram-swap ];

      services.zram-swap.enable = true;

      boot.kernel.sysctl."vm.swappiness" = 180;
    };
}
