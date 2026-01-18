{...}: {
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda"; # You define the disk here...
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/"; # ...but you mount the partitions here!
              };
            };
          };
        };
      };
    };
  };
}
