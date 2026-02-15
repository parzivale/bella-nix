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

      input = {
        mouse.accel-profile = "flat";
        focus-follows-mouse.enable = true;
      };

      outputs = {
        HDMI-A-1 = {
          variable-refresh-rate = true;
          focus-at-startup = true;
          mode = {
            width = 2560;
            height = 1440;
            refresh = 143.912;
          };
          position = {
            x = 0;
            y = 0;
          };
        };
      };
    };
  };
}
