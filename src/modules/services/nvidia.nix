{
  flake.modules.nixos.nvidia = {config, ...}: let
    user = config.systemConstants.username;
  in {
    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia = {
      modesetting.enable = true;
      open = true;
    };

    home-manager.users.${user}.xdg.desktopEntries.nvidia-settings = {
      name = "NVIDIA Settings";
      noDisplay = true;
    };
  };
}
