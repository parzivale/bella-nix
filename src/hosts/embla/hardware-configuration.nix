{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: {
  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
