{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {config, ...}: {
      home.packages = [pkgs.playerctl pkgs.wireplumber];

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

        "Mod+Comma".action = consume-window-into-column;
        "Mod+Period".action = expel-window-from-column;

        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+Ctrl+F".action = expand-column-to-available-width;

        # "Mod+M".action = maximize-window-to-edges;
        "Mod+W".action = close-window;
        "Mod+R".action = switch-preset-column-width;
        "Mod+G".action = switch-preset-window-height;
        "Mod+Shift+G".action = reset-window-height;
        "Mod+Tab".action = toggle-overview;
        "Mod+T".action = toggle-window-floating;

        "Mod+C".action = center-column;
        "Mod+Ctrl+C".action = center-visible-columns;

        "Mod+Home".action = focus-column-first;
        "Mod+End".action = focus-column-last;

        "Mod+Shift+P".action = power-off-monitors;

        "Mod+Shift+U".action = move-workspace-down;
        "Mod+Shift+I".action = move-workspace-up;

        "Mod+Shift+E".action.quit.skip-confirmation = true;

        "Print".action.screenshot = [];

        # Notification center

        # Volume controls
        "XF86AudioRaiseVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
        "XF86AudioLowerVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
        "XF86AudioMute".action.spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];

        # Mic mute
        "XF86AudioMicMute".action.spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];

        # Playback controls
        "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
        "XF86AudioNext".action.spawn = ["playerctl" "next"];
        "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
      };
    };
  };
}
