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
          PROTON_ENABLE_WAYLAND = 1;
          DRI_PRIME = 1;
          STEAM_FRAME_FORCE_CLOSE = 1;
          STEAM_DISABLE_BROWSER_COMPOSITOR = 1;
        };
        extraArgs = builtins.concatStringsSep " " [
          "-cef-single-process"
          "-cef-in-process-gpu"
          "-cef-disable-gpu"
          "-cef-disable-gpu-compositing"
          "+open steam://open/minigameslist"
        ];
        extraPkgs = pkgs: [pkgs.gamemode pkgs.faudio];
        extraLibraries = pkgs: [pkgs.gamemode];
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };
    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
          inhibit_screensaver = 1;
          desiredgov = "performance";
          igpu_desiredgov = "powersave";
          igpu_power_threshold = 0.3;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };

    preservation = config.helpers.mkPreserve user {
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
