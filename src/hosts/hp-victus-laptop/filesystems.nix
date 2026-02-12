{
  fileSystems."/persistent" = {
    device = "/dev/disk/by-id/nvme-WDC_PC_SN730_SDBPNTY-512G-1006_210862801954-part4";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=persistent"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-id/nvme-WDC_PC_SN730_SDBPNTY-512G-1006_210862801954-part4";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=nix"];
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "size=8G" "mode=755"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-WDC_PC_SN730_SDBPNTY-512G-1006_210862801954-part1";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
}
