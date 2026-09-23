{ inputs, ... }:
{
  flake.modules.nixos.nvidia =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      services.xserver.videoDrivers = [ "nvidia" ];
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
