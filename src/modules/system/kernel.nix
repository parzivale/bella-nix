let
  # `boot.kernelPackages` is the same option in both module sets, so this is
  # the same line twice rather than two translations of one idea.
  kernel =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
in
{
  flake.modules.nixos.kernel = kernel;
  flake.modules.finix.kernel = kernel;
}
