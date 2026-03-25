{...}: {
  flake.modules.nixos.iwd = {
    networking.wireless.iwd.enable = true;

    preservation.preserveAt."/persistent".directories = [
      "/var/lib/iwd"
    ];
  };
}
