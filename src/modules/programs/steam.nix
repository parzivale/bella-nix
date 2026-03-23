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
          STEAM_DISABLE_OVERLAY = "1";
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
    };
    programs.gamemode.enable = true;

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
