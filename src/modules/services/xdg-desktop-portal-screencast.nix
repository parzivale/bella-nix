{ ... }:
{
  # niri implements the Mutter ScreenCast DBus interface itself, so the gnome
  # portal backend is what turns that into org.freedesktop.portal.ScreenCast -
  # the gtk backend has no ScreenCast implementation. Without this, browsers
  # report screen sharing as a permission error, since the interface they ask
  # for does not exist.
  flake.modules.nixos.xdg-desktop-portal-screencast =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };

  flake.modules.finix.xdg-desktop-portal-screencast =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        portals = [ pkgs.xdg-desktop-portal-gnome ];
        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
}
