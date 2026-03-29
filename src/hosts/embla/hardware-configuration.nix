{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: {
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/disk/by-id/" + builtins.readFile ./boot_disk;
    };
  };

  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
