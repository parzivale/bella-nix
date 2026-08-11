{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  hardware = {
    enableAllFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    facter.reportPath = ./facter.json;
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
