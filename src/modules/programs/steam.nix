{ inputs, ... }:
let
  # A game's launch options become `gamescope-run %command%`: gamescope nested
  # at the size and refresh rate of the output the game starts on, with
  # gamemode. Extra gamescope flags go before a `--`:
  #
  #   gamescope-run -F fsr -w 1920 -h 1080 -- %command%
  #
  # `gamescope` and `niri` are looked up on PATH, which steam's FHS sandbox
  # inherits from the host - so a setcap gamescope in /run/wrappers wins, and
  # nothing here assumes niri is installed.
  gamescope-run =
    pkgs:
    pkgs.writers.writeNuBin "gamescope-run" ''
      # niri knows which output has focus, so ask it when it is there.
      def niri-mode [] {
        let output = niri msg --json focused-output | from json
        let mode = $output.modes | get $output.current_mode
        { width: $mode.width, height: $mode.height, refresh: ($mode.refresh_rate / 1000) }
      }

      # Any compositor implements wl_output, but it has no notion of focus, so
      # the biggest output's current mode stands in for "the one I'm at".
      def wl-output-mode [] {
        ^${pkgs.wayland-utils}/bin/wayland-info --interface wl_output
        | lines
        | str trim
        | window 2
        | where {|pair| ($pair.1 | str starts-with 'flags:') and ($pair.1 | str contains 'current') }
        | each {|pair| $pair.0 | parse 'width: {width} px, height: {height} px, refresh: {refresh} Hz,' | first }
        | each {|mode| { width: ($mode.width | into int), height: ($mode.height | into int), refresh: ($mode.refresh | into float) } }
        | sort-by {|mode| $mode.width * $mode.height }
        | last
      }

      def --wrapped main [...rest] {
        let split = $rest | enumerate | where item == '--' | get index.0?
        let extra = if $split == null { [] } else { $rest | take $split }
        let game = if $split == null { $rest } else { $rest | skip ($split + 1) }

        let mode = if ($env.NIRI_SOCKET? | is-not-empty) and (which niri | is-not-empty) {
          niri-mode
        } else {
          wl-output-mode
        }

        # --expose-wayland because the steam package sets PROTON_ENABLE_WAYLAND;
        # without it a Wayland game has nowhere inside gamescope to go.
        (^gamescope -f
          -W $mode.width -H $mode.height -r ($mode.refresh | math round)
          --expose-wayland
          ...$extra
          -- ${pkgs.gamemode}/bin/gamemoderun ...$game)
      }
    '';
in
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
      imports = [
        # proton-cachyos below comes from chaotic-nyx, not nixpkgs.
        inputs.self.modules.nixos.chaotic
        # `programs.gamemode` creates the gamemode group, so this is where
        # membership in it belongs.
        inputs.self.modules.nixos.user
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
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-cachyos_x86_64_v3
        ];
      };

      # Nested, per game, through `gamescope-run` above. Resolution and refresh
      # rate differ per output, so they are found at launch rather than set in
      # `args`.
      programs.gamescope.enable = true;
      environment.systemPackages = [ (gamescope-run pkgs) ];

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

      users.users.${user}.extraGroups = [ "gamemode" ];

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
        inputs.self.modules.finix.user
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

      # Nested, per game, as on NixOS. The option comes in with
      # community-modules' steam module, which imports its gamescope module.
      programs.gamescope.enable = true;
      environment.systemPackages = [ (gamescope-run pkgs) ];

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

      users.users.${user}.extraGroups = [ "gamemode" ];

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
