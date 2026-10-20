{ inputs, ... }:
let
  # Steam app IDs that launch without gamescope, for games that will not run
  # under it. The ID is the number in the game's store URL.
  gamescopeOptOut = [ ];

  # Runs a command nested in gamescope at the size and refresh rate of the
  # output it starts on. Every game goes through it via
  # `launchShell` below; extra gamescope flags go before a `--`:
  #
  #   gamescope-run -F fsr -w 1920 -h 1080 -- <command>
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

        # Already inside gamescope - launched by the launch shell with an old
        # `gamescope-run %command%` still in the game's launch options, or from
        # a gamescope session - so run the command as it is.
        if ($env.GAMESCOPE_WAYLAND_DISPLAY? | is-not-empty) {
          exec ($game | first) ...($game | skip 1)
        }

        let mode = if ($env.NIRI_SOCKET? | is-not-empty) and (which niri | is-not-empty) {
          niri-mode
        } else {
          wl-output-mode
        }

        # No --expose-wayland: games reach gamescope over X11, through its own
        # Xwayland, which is the path it is built around. Its Wayland server
        # lacks wl_subcompositor and wp_viewporter, both of which winewayland
        # requires, so a Proton told to use Wayland there gets no display
        # driver at all.
        (^gamescope -f
          -W $mode.width -H $mode.height -r ($mode.refresh | math round)
          ...$extra
          -- ...$game)
      }
    '';

  # Steam runs every game through `/bin/sh -c "<command line>"` once it has
  # built the game's environment, unless STEAM_GAME_LAUNCH_SHELL is set - then
  # it runs `$STEAM_GAME_LAUNCH_SHELL "<command line>"`, with no `-c`. That
  # flag is only added on the /bin/sh path (steamclient.so, around the getenv),
  # so the command line arrives here as `$1` and the `-c` is ours to supply.
  # The command line already carries the game's own launch options, so pointing
  # that variable here puts every game in gamescope without touching any of
  # them.
  #
  # Opting out is by app ID because anything set in launch options is only
  # evaluated inside the command line, after this has already decided. An
  # opted-out game that wants gamescope with flags of its own can still say
  # `gamescope-run -F fsr -- %command%` in its launch options.
  #
  # An opted-out game runs straight on the desktop compositor, so it is the one
  # place Proton's native Wayland driver has something to talk to; it is set
  # there and nowhere else, so nothing inside gamescope ever sees it.
  #
  # gamemode is asked for here, for this shell's own PID, rather than by
  # preloading libgamemodeauto with gamemoderun. The preload is inherited into
  # Steam's runtime container, where the library path it carries does not exist,
  # so every process in there failed to dlopen libgamemode.so. Steam's FHS
  # sandbox shares the host's PID namespace, so the daemon sees the real PID,
  # and every branch below execs, so that PID lives exactly as long as the game
  # and gamemode's reaper ends it when the game does. Renice and ioprio land on
  # this process rather than the game's own; the governor, GPU and screensaver
  # settings are system-wide and unaffected.
  launchShell =
    pkgs:
    pkgs.writeShellScript "steam-game-launch-shell" ''
      ${pkgs.gamemode}/bin/gamemoded -r$$ >/dev/null 2>&1

      ${pkgs.lib.optionalString (gamescopeOptOut != [ ]) ''
        case "''${SteamAppId:-''${SteamGameId:-}}" in
          ${pkgs.lib.concatMapStringsSep "|" toString gamescopeOptOut})
            export PROTON_ENABLE_WAYLAND=1
            exec /bin/sh -c "$1"
            ;;
        esac
      ''}
      exec ${gamescope-run pkgs}/bin/gamescope-run -- /bin/sh -c "$1"
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
            STEAM_GAME_LAUNCH_SHELL = "${launchShell pkgs}";
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

      # Every game is nested in gamescope through the launch shell above.
      # Resolution and refresh rate differ per output, so they are found at
      # launch rather than set in `args`. `gamescope-run` stays on PATH for
      # opted-out games that want it with flags of their own.
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
            STEAM_GAME_LAUNCH_SHELL = "${launchShell pkgs}";
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

      # Every game in gamescope, as on NixOS. The option comes in with
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
