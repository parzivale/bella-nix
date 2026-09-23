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
}
