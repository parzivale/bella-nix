{
  flake.modules.nixos.discord = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = "discordcanary";
        }
      ];
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gnome]; # or wlr for wlroots-based
    };

    home-manager.users.${user} = {
      home.sessionVariables.NIXOS_OZONE_WL = "1";
      programs.discord = {
        enable = true;
        package = pkgs.discord-canary;
      };
    };
  };
}
