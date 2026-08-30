{ inputs }:
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/" + builtins.readFile ./boot_disk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            persistent = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = {
                  nix = {
                    mountOptions = [
                      "compress=zstd"
                      "discard=async"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                  persistent = {
                    mountpoint = "/persistent";
                    mountOptions = [
                      "discard=async"
                      "compress=zstd"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "size=6G"
        "mode=755"
      ];
    };
  };

  # disko's btrfs-subvolume module doesn't set neededForBoot, but preservation's
  # inInitrd bind-mounts (machine-id, ssh host keys, random-seed) run during
  # initrd before switch-root — without this, /persistent isn't mounted yet at
  # that point and the bind-mounts silently attach to the empty tmpfs root
  # instead of the real disk, so machine-id (and host keys) regenerate every boot.
  fileSystems."/persistent".neededForBoot = true;

}
