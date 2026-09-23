{ inputs, ... }:
{
  flake.modules.nixos.steam =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
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

  flake.modules.finix.steam =
    { config, pkgs, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [
        inputs.self.modules.finix.chaotic
        inputs.community-modules.nixosModules.steam
        inputs.finix.nixosModules.gamemode
      ];

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
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-cachyos_x86_64_v3
        ];
      };

      # No `remotePlay.openFirewall` or `dedicatedServer.openFirewall`: the
      # community module has neither, and finix's firewall takes port numbers
      # rather than a service saying "mine". Opening them means naming steam's
      # ports here, which is nixpkgs' knowledge rather than mine, so a finix
      # host wanting remote play says so deliberately.
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
