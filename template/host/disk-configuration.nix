{...}: {
  fileSystems."/nix" = {
    device = "/persistent/nix";
    fsType = "none";
    options = ["bind"];
  };

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
                mountOptions = ["umask=0077"];
              };
            };
            persistent = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persistent";
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
