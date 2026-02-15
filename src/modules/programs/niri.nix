{inputs, ...}: {
  flake.modules.nixos.niri = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = [
      inputs.niri-flake.nixosModules.niri
    ];

    # autolaunch niri

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri";
        user = user;
      };
    };

    services.getty.autologinUser = user;
    programs.niri.enable = true;

    home-manager.users.${user}.programs.niri.settings = {
      binds = with config.lib.niri.actions; {
        "Mod+Return".action.spawn = "wezterm";
      };

      outputs = {
        HDMI-A-1 = {
          focus-at-startup = true;
          position = {
            x = 0;
            y = 0;
          };
        };
      };
    };
  };
}
