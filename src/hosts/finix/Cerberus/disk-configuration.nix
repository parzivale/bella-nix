_: _: {
  # disko is a nixos module, so a finix host cannot be handed the declarative
  # layout the nixos Cerberus uses. These are the mounts that layout produces,
  # read off `config.fileSystems` there and written out - the same partitions, by
  # the same labels, with the same options.
  #
  # Which means this file describes the disk rather than creating it. The
  # partitioning still belongs to the nixos side, or to `bnix host bootstrap`; a
  # finix Cerberus is a different system on a disk that already exists.
  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "x-initrd.mount"
        "defaults"
        "size=6G"
        "mode=755"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

    "/nix" = {
      device = "/dev/disk/by-partlabel/disk-main-persistent";
      fsType = "btrfs";
      options = [
        "x-initrd.mount"
        "compress=zstd"
        "discard=async"
        "noatime"
        "subvol=nix"
      ];
    };

    "/persistent" = {
      device = "/dev/disk/by-partlabel/disk-main-persistent";
      fsType = "btrfs";
      options = [
        "x-initrd.mount"
        "discard=async"
        "compress=zstd"
        "subvol=persistent"
      ];
    };
  };
}
