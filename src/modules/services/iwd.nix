{...}: {
  flake.modules.nixos.iwd = {
    networking.wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = true;
    };

    preservation.preserveAt."/persistent".directories = [
      "/var/lib/iwd"
    ];
  };
}
