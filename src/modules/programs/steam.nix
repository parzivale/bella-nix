{
  flake.modules.nixos.steam = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
    mkWrappedSteam = args: let
      base = pkgs.steam.override args;
    in
      (pkgs.symlinkJoin {
        name = "steam-gamemoded";
        paths = [
          (pkgs.writeShellScriptBin "steam" ''
            exec ${pkgs.gamemode}/bin/gamemoderun ${base}/bin/steam "$@"
          '')
          base
        ];
        inherit (base) meta;
      })
      // {
        inherit (base) run;
      };
  in {
    programs.steam = {
      enable = true;
      package = pkgs.lib.makeOverridable mkWrappedSteam {
        extraEnv = {
          PROTON_ENABLE_WAYLAND = 1;
          DRI_PRIME = 1;
          STEAM_FRAME_FORCE_CLOSE = 1;
          STEAM_DISABLE_BROWSER_COMPOSITOR = 1;
          STEAM_DISABLE_OVERLAY = 1;
        };
        extraArgs = builtins.concatStringsSep " " [
          "-cef-single-process"
          "-cef-in-process-gpu"
          "-cef-disable-gpu"
          "-cef-disable-gpu-compositing"
          "+open steam://open/minigameslist"
        ];
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraPackages = [pkgs.faudio];
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
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
          nv_powermizer_mode = 1;
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
