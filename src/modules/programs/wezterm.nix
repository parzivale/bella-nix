{inputs, ...}: {
  flake.modules.homeManager.wezterm = {
    pkgs,
    lib,
    osConfig,
    ...
  }: let
    user = osConfig.systemConstants.username;
    currentHost = osConfig.networking.hostName;
    allHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../hosts));
    remoteHosts = builtins.filter (name: name != currentHost && name != "bootstrap") allHosts;

  in {
    home.packages = [pkgs.wl-clipboard];
    programs = {
      wezterm = {
        enable = true;
        package = inputs.wezterm.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
          check_for_updates = false;
          enable_tab_bar = false;
          enable_kitty_graphics = true;
          ssh_domains = map (host: {
            name = host;
            remote_address = host;
            username = user;
            multiplexing = "None";
          }) remoteHosts;
          keys = [
            {
              key = "t";
              mods = "CTRL|SHIFT";
              action = lib.generators.mkLuaInline "wezterm.action.DisableDefaultAssignment";
            }
            {
              key = "t";
              mods = "SUPER";
              action = lib.generators.mkLuaInline "wezterm.action.DisableDefaultAssignment";
            }
            {
              key = "w";
              mods = "CTRL";
              action = lib.generators.mkLuaInline "wezterm.action.CloseCurrentTab { confirm = true }";
            }
            {
              key = "v";
              mods = "CTRL|SHIFT";
              action = lib.generators.mkLuaInline "wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }";
            }
            {
              key = "h";
              mods = "CTRL|SHIFT";
              action = lib.generators.mkLuaInline "wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }";
            }
            {
              key = "w";
              mods = "CTRL|SHIFT";
              action = lib.generators.mkLuaInline "wezterm.action.CloseCurrentPane { confirm = true }";
            }
          ];
        };
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
      })
      remoteHosts);
  };

  flake.modules.nixos.wezterm = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.wezterm];
  };
}
