{config, ...}: {
  programs.niri.settings = {
    binds = with config.lib.niri.actions; {
      "Mod+Return".action.spawn = ["wezterm" "+new-window"];
    };
  };
}
