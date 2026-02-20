{
  flake.modules.nixos.niri = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {config, ...}: {
      programs.niri.settings.binds = with config.lib.niri.actions; {
        "Mod+Shift+Slash".action = show-hotkey-overlay;

        "Mod+Left".action = focus-column-or-monitor-left;
        "Mod+Right".action = focus-column-or-monitor-right;
        "Mod+Down".action = focus-window-or-workspace-down;
        "Mod+Up".action = focus-window-or-workspace-up;

        "Mod+Ctrl+Left".action = move-column-left-or-to-monitor-left;
        "Mod+Ctrl+Right".action = move-column-right-or-to-monitor-right;
        "Mod+Ctrl+Down".action = move-window-down-or-to-workspace-down;
        "Mod+Ctrl+Up".action = move-window-up-or-to-workspace-up;

        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+W".action = close-window;
        "Mod+R".action = switch-preset-column-width;
        "Mod+Tab".action = toggle-overview;

        "Mod+Home".action = focus-column-first;
        "Mod+End".action = focus-column-last;

        "Mod+Shift+U".action = move-workspace-down;
        "Mod+Shift+I".action = move-workspace-up;

        "Mod+Shift+E".action.quit.skip-confirmation = true;

        "Print".action.screenshot = [];
      };
    };
  };
}
