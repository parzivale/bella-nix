{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  fileSystems."/" = {
    device = "/dev/sad";
    fsType = "ext4";
  };
}
