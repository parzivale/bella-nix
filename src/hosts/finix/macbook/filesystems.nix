_: {
  # An Asahi install: macOS still owns the disk, and these are the partitions left for it.
  # Ported unchanged from the nixos host - `neededForBoot`, subvolumes and a tmpfs root are
  # all said the same way here.
  fileSystems = {
    "/persistent" = {
      device = "/dev/nvme0n1p5";
      neededForBoot = true;
      fsType = "btrfs";
      options = [ "subvol=persistent" ];
    };

    "/nix" = {
      device = "/dev/nvme0n1p5";
      neededForBoot = true;
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=6G"
        "mode=755"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-partuuid/8a5dc817-ca90-4ec5-9e27-7e8c2f18aaa0";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
        # The root is a tmpfs, so /boot's mount point does not exist until something makes it.
        # `mount -a` will not - this is util-linux's own option for it, not a systemd one, and
        # it is what the Cerberus port needed for the same reason.
        "X-mount.mkdir"
      ];
    };
  };
}
