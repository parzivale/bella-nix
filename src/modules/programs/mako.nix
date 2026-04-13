{...}: {
  flake.modules.nixos.mako = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.services.mako = {
      enable = true;
      settings = {
        default-timeout = 5000;
        borderRadius = 8;
        margin = "10";
        padding = "12";
        iconPath = "/run/current-system/sw/share/icons/Papirus-Dark";
      };
    };
  };
}
