let
  # A compressed cache in front of a disk swap device, for hosts that have one. Unlike zram
  # stacked over a swapfile, zswap evicts to the disk in LRU order, so the compressed tier
  # keeps the hot pages instead of whatever was swapped first. The shrinker writes cold pages
  # back ahead of the pool filling. Pool size and accept threshold stay at the kernel defaults
  # (20% / 90%), and swappiness is left alone: 180 is tuned for zram-only.
  #
  # Hosts without a disk swap device want `zram` instead; zswap does nothing without one, and
  # the two should not be combined.
  kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.shrinker_enabled=1"
  ];
in
{
  flake.modules.nixos.zswap = {
    boot.kernelParams = kernelParams;
  };

  flake.modules.finix.zswap = {
    boot.kernelParams = kernelParams;
  };
}
