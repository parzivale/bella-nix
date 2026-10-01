_: {
  # An Asahi install: macOS still owns the disk, and these are the partitions left for it.
  # Ported unchanged from the nixos host - `neededForBoot`, subvolumes and a tmpfs root are
  # all said the same way here.
  #
  # `noCheck` on the two btrfs entries is what changed, and only because the initrd went away.
  # `neededForBoot` means "mounted before the init runs", which finix-init does out of
  # finix-init.json; a check is the other thing stage 1 was for, and it is the one this machine
  # has no moment for. An initrd is the single point at which a filesystem is present and not
  # yet mounted - without one the first thing to touch these mounts them, so a `pass` could only
  # point fsck at a live filesystem. Nothing here runs fsck at all (the contract's
  # mount-filesystems unit is `mount -a`), so this says out loud what was already true, and
  # root.nix asserts on it rather than letting it be implied. btrfs is checked by `btrfs scrub`
  # on a running machine anyway, which is a different and better thing than a boot-time fsck.
  fileSystems = {
    "/persistent" = {
      device = "/dev/nvme0n1p5";
      neededForBoot = true;
      noCheck = true;
      fsType = "btrfs";
      options = [ "subvol=persistent" ];
    };

    "/nix" = {
      device = "/dev/nvme0n1p5";
      neededForBoot = true;
      noCheck = true;
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
