{inputs, ...}: {
  flake.modules = {
    nixos.niri = {config, ...}: let
      user = config.vars.username;
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
    };

    home-manager.niri = {config, ...}: let
      user = config.vars.username;
    in {
      home-manager.users.${user}.programs.niri.settings = {
        binds = with config.lib.niri.actions; {
          "Mod+Return".action.spawn = "wezterm";
          "Print".action = screenshot;

          "Mod+H".action = focus-column-or-monitor-left;
          "Mod+L".action = focus-column-or-monitor-right;
          "Mod+J".action = focus-window-or-workspace-down;
          "Mod+K".action = focus-window-or-workspace-up;

          "Mod+Shift+H".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+L".action = move-column-right-or-to-monitor-right;
          "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+K".action = move-window-up-or-to-workspace-up;

          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;
          "Mod+Q".action = close-window;
          "Mod+R".action = switch-preset-column-width;
          "Mod+Tab".action = toggle-overview;
          "Mod+T".action = toggle-column-tabbed-display;

          "Mod+Shift+E".action.quit.skip-confirmation = true;
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
  };
}
