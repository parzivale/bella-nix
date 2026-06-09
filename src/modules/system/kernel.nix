{
  flake.modules.nixos.kernel =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
}
