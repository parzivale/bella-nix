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

      # The portal and the gnome backend, but not the choice between backends:
      # finix's `xdg.portal` takes `portals` and nothing else, so there is no
      # `config.common` to say which implementation serves ScreenCast. With one
      # backend installed the question does not arise; it will the moment a
      # second one is.
      xdg.portal = {
        enable = true;
        portals = [ pkgs.xdg-desktop-portal-gnome ];
      };
    };
}
