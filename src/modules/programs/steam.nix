{ inputs, ... }:
{
  flake.modules.nixos.steam =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.systemConstants.username;
    in
    {
      # proton-cachyos below comes from chaotic-nyx, not nixpkgs.
      imports = [ inputs.self.modules.nixos.chaotic ];

      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          extraEnv = {
            PROTON_ENABLE_WAYLAND = 1;
          };
          extraPkgs = pkgs: [
            pkgs.gamemode
            pkgs.faudio
          ];
          extraLibraries = pkgs: [ pkgs.gamemode ];
        };
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-cachyos_x86_64_v3
        ];
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

      state.preserve.users.${user} = {
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
