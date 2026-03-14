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
        extraArgs = "-no-browser -nofriendsui +open steam://open/minigameslist";
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
