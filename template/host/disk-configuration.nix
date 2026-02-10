{...}: {
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
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            persistent = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
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
}
