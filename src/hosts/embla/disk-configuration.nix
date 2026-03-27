{...}: {
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/" + builtins.readFile ./boot_disk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              type = "EF02";
              size = "1M";
            };
            persistent = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
                subvolumes = {
                  boot = {
                    mountpoint = "/boot";
                    mountOptions = [
                      "compress=zstd"
                      "discard=async"
                    ];
                  };
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
