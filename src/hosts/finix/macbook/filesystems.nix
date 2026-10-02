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
      # `PARTUUID=` rather than /dev/disk/by-partuuid/, and the difference is who resolves it.
      #
      # That path is a symlink udev makes once it is running, and with no initrd nothing has run
      # udev when the filesystems are mounted: the contract's mount-filesystems task starts
      # before udevd does, which is harmless on a machine whose stage 1 already populated /dev
      # and fatal on one with no stage at all. It fails exactly as a missing device does:
      #
      #   [FAIL] Mounting filesystems from /etc/fstab
      #   mount: /boot: fsconfig() failed: /dev/disk/by-partuuid/8a5dc817-...
      #
      # and because `mount -a` is one task for every filesystem, one entry failing fails all of
      # it. `mount-filesystems-started` never fires, the sysinit barrier waits on it for ever,
      # and the boot stops before syslogd - so nothing records why, on the machine or anywhere
      # else. Four generations died of this.
      #
      # `PARTUUID=` is read by libblkid out of the partition table itself, so it needs nothing
      # running and resolves identically with an initrd or without one. The same reasoning
      # modules/boot/root.nix applies to `root=`, which translates these two forms and refuses
      # the rest; fstab is the half that was left naming a symlink.
      #
      # Mounted at all because the bootloader installer assumes it: limine-install walks up from
      # /boot with os.path.ismount to find the EFI partition, so an unmounted /boot resolves to
      # the tmpfs root and it installs kernels there - a switch which reports success and leaves
      # the real ESP untouched. Not mounting it is a worse failure than failing to mount it.
      device = "PARTUUID=8a5dc817-ca90-4ec5-9e27-7e8c2f18aaa0";
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
