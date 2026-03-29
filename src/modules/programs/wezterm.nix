{inputs, ...}: {
  flake.modules.nixos.wezterm = {config, lib, pkgs, ...}: let
    user = config.systemConstants.username;
    currentHost = config.networking.hostName;
    allHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../hosts));
    remoteHosts = builtins.filter (name: name != currentHost && name != "bootstrap") allHosts;

    mkSshDomain = host: ''
      { name = '${host}', remote_address = '${host}', username = '${user}', multiplexing = 'None' },
    '';
  in {
    home-manager.users.${user} = {pkgs, ...}: {
      home.packages = [pkgs.wl-clipboard];
      programs = {
        wezterm = {
          enable = true;
          package = inputs.wezterm.packages.${pkgs.system}.default;
          extraConfig = ''
            config.enable_tab_bar = false
            config.ssh_domains = {
              ${lib.concatMapStrings mkSshDomain remoteHosts}
            }
            config.keys = {
              {
                key = 't',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.DisableDefaultAssignment,
              },
              {
                key = 't',
                mods = 'SUPER',
                action = wezterm.action.DisableDefaultAssignment,
              },
              {
                key = 'w',
                mods = 'CTRL',
                action = wezterm.action.CloseCurrentTab { confirm = true },
              },
              {
                key = 'v',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
              },
              {
                key = 'h',
                mods = 'CTRL|SHIFT',
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

      xdg.desktopEntries = lib.listToAttrs (map (host: {
        name = "ssh-${host}";
        value = {
          name = "SSH: ${host}";
          exec = "wezterm connect ${host}";
          icon = "utilities-terminal";
          comment = "SSH into ${host} via WezTerm";
          categories = ["System" "TerminalEmulator"];
        };
      }) remoteHosts);
    };
  };
}
