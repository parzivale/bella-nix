{
  flake.modules.nixos.steam = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          STEAM_FRAME_FORCE_CLOSE = "1";
          STEAM_DISABLE_BROWSER_COMPOSITOR = "1";
        };
        extraArgs = "-no-browser -cef-single-process -cef-in-process-gpu -no-cef-sandbox -start steam://open/minigameslist";
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraPackages = [pkgs.faudio];
    };
    programs.gamemode.enable = true;
    home-manager.users.${user} = {
      home.packages = [pkgs.steamcmd pkgs.steam-tui];

      xdg.desktopEntries.steam = {
        name = "Steam";
        noDisplay = true;
      };

      xdg.desktopEntries.st = {
        name = "Steam TUI";
        exec = "st";
        terminal = true;
        categories = ["Game"];
      };

      programs.nushell.extraConfig = ''
        def st [] {
          let cred_path = $"($env.HOME)/.steam/steam/config/config.vdf"
          if not ($cred_path | path exists) {
            steamcmd +login (input "Steam username: ") +quit
          }
          steam-tui
        }
      '';
    };

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".steam";
          mode = "0755";
        }
        {
          directory = ".local/share/Steam";
          mode = "0755";
        }
      ];
    };
  };
}
