{
  config,
  vars,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user}.programs.niri.settings = {
    binds = with config.lib.niri.actions; {
      "Mod+Return".action.spawn = "wezterm";
    };
  };
}
