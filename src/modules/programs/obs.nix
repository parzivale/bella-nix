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
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.obs ];

      state.preserve.users.${user} = {
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

  flake.modules.finix.obs =
    { config, pkgs, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.obs ];

      state.preserve.users.${user} = {
        directories = [ { directory = ".config/obs-studio"; } ];
      };

      # niri implements the Mutter ScreenCast DBus interface itself, so the gnome
      # backend is what makes it available to obs as a source - the gtk backend has
      # no ScreenCast implementation. Which is now sayable: finix's `xdg.portal`
      # took `portals` and nothing else until `config` was added for exactly this,
      # the moment a second backend arrived.
      xdg.portal = {
        enable = true;
        portals = [ pkgs.xdg-desktop-portal-gnome ];
        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
}
