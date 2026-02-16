{
  flake.modules.nixos.discord = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
      config = {
        common.default = ["gnome"];
      };
    };
    home-manager.users.${user} = {
      programs.discord = {
        enable = true;
        package = pkgs.discord-canary;
      };
    };
  };
}
