{inputs}: {
  fileSystems."/persistent" = {
    device = "/dev/nvme0n1p5";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=persistent"];
  };

  fileSystems."/nix" = {
    device = "/dev/nvme0n1p5";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=nix"];
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=2G" "mode=755"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/8a5dc817-ca90-4ec5-9e27-7e8c2f18aaa0";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
}
