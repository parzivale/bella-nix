{ inputs, ... }:
{
  flake.modules.homeManager.obs =
    { ... }:
    {
      programs.obs-studio.enable = true;
    };

  flake.modules.nixos.obs =
    { config, pkgs, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.obs ];

      preservation = config.helpers.mkPreserve user {
        directories = [ { directory = ".config/obs-studio"; } ];
      };

      # niri implements the Mutter ScreenCast DBus interface itself, so the
      # gnome portal backend is what actually serves OBS's screen capture
      # source (the gtk backend has no ScreenCast implementation).
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
}
