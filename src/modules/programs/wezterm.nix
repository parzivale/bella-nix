{
  flake.modules.nixos.wezterm = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs = {
        wezterm = {
          enable = true;
          extraConfig = ''
            config.keys = {
              {
                key = 'w',
                mods = 'CTRL',
                action = wezterm.action.CloseCurrentTab { confirm = true },
              },
              {
                key = 'v',
                mods = 'CTRL',
                action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
              },
              {
                key = 'h',
                mods = 'CTRL',
                action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
              },
              {
                key = 'w',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.CloseCurrentPane { confirm = true },
              },
            }
          '';
        };
        niri.settings.binds."Mod+Return".action.spawn = "wezterm";
      };
    };
  };
}
