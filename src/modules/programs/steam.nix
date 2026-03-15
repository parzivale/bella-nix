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
        extraArgs = "-no-browser -dev -console -nofriendsui -no-dwrite -nointro -nobigpicture -nofasthtml -nocrashmonitor -noshaders -no-shared-textures -disablehighdpi -cef-single-process -cef-in-process-gpu -single_core -cef-disable-d3d11 -cef-disable-sandbox -disable-winh264 -cef-force-32bit -no-cef-sandbox -vrdisable -cef-disable-breakpad";
      };
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server hosting
      extraPackages = [pkgs.faudio];
    };
    programs.gamemode.enable = true; # gamemoderun %command%
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
