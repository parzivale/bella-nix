{inputs}: {
  lib,
  ...
}: {
  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
