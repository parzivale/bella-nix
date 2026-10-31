{ inputs, ... }:
let
  # Steam app IDs that launch without gamescope, for games that will not run
  # under it. The ID is the number in the game's store URL.
  gamescopeOptOut = [ ];

  # Runs a command nested in gamescope at the size and refresh rate of the
  # output it starts on. Every game goes through it via
  # `gameWrappers` below; extra gamescope flags go before a `--`:
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

  # Every game, in order, outermost first: given the rest of the chain and then
  # the game's command line as arguments, each `exec`s the rest. The command
  # line already carries the game's own launch options, so this puts every game
  # in gamescope without touching any of them. On finix this list is
  # `programs.steam.gameWrappers`; on nixos `launchShell` below runs it.
  #
  # gamemode is asked for first, for the wrapper's own PID, rather than by
  # preloading libgamemodeauto with gamemoderun. The preload is inherited into
  # Steam's runtime container, where the library path it carries does not exist,
  # so every process in there failed to dlopen libgamemode.so. Steam's FHS
  # sandbox shares the host's PID namespace, so the daemon sees the real PID,
  # and the wrappers exec down to gamescope-run, so that PID lives exactly as
  # long as the game and gamemode's reaper ends it when the game does. It has to
  # come before gamescope, which starts the game as a child rather than becoming
  # it. Renice and ioprio land on that process rather than the game's own; the
  # governor, GPU and screensaver settings are system-wide and unaffected.
  #
  # Opting out of gamescope is by app ID because anything set in launch options
  # is only evaluated inside the command line, after this has already decided.
  # An opted-out game that wants gamescope with flags of its own can still say
  # `gamescope-run -F fsr -- %command%` in its launch options.
  #
  # An opted-out game runs straight on the desktop compositor, so it is the one
  # place Proton's native Wayland driver has something to talk to; it is set
  # there and nowhere else, so nothing inside gamescope ever sees it.
  gameWrappers = pkgs: [
    (pkgs.writeShellScript "steam-gamemode" ''
      ${pkgs.gamemode}/bin/gamemoded -r$$ >/dev/null 2>&1
      exec "$@"
    '')
    (pkgs.writeShellScript "steam-gamescope" ''
      ${pkgs.lib.optionalString (gamescopeOptOut != [ ]) ''
        case "''${SteamAppId:-''${SteamGameId:-}}" in
          ${pkgs.lib.concatMapStringsSep "|" toString gamescopeOptOut})
            export PROTON_ENABLE_WAYLAND=1
            exec "$@"
            ;;
        esac
      ''}
      exec ${gamescope-run pkgs}/bin/gamescope-run -- "$@"
    '')
  ];

  # nixpkgs' steam module has no `gameWrappers`, so on nixos the launch shell is
  # written here, as community-modules writes it on finix. With
  # STEAM_GAME_LAUNCH_SHELL set, steam runs `$STEAM_GAME_LAUNCH_SHELL "<command
  # line>"` instead of `/bin/sh -c "<command line>"`, with no `-c`. That flag is
  # only added on the /bin/sh path (steamclient.so, around the getenv), so the
  # command line arrives here as `$1` and the `-c` is ours to supply.
  launchShell =
    pkgs:
    pkgs.writeShellScript "steam-game-launch-shell" ''
      exec ${pkgs.lib.concatStringsSep " " (gameWrappers pkgs)} /bin/sh -c "$1"
    '';

  # Library art for non-Steam games, cut from whatever the game's own site or
  # launcher has. Each kind has a fixed shape - grid 600x900, wide 920x430,
  # hero 1920x620 - so the source is scaled to cover it and cropped from the
  # middle, with `over`, a logo say, laid on top. With no size it is only made a
  # PNG.
  steamArt =
    pkgs:
    {
      name,
      src,
      size ? null,
      over ? null,
    }:
    pkgs.runCommand "${name}.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick ${src} ${
        pkgs.lib.optionalString (size != null) "-resize ${size}^ -gravity center -extent ${size}"
      } ${
        pkgs.lib.optionalString (
          over != null
        ) ''\( ${over.src} -resize ${over.width}x \) -gravity ${over.gravity} -geometry +0+60 -composite''
      } $out
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
      art = steamArt pkgs;

      # Star Stable's site: a 1920x1080 key art shot and the square brand mark.
      starstableKey = pkgs.fetchurl {
        url = "https://cms-proxy.starstable.com/65346/1788520888-iae_images_westphalian_1920x1080-1.jpg";
        hash = "sha256-AXsJVESi0BygouKUeqiE1IOFRvKUjXaW0PXg3pWbESQ=";
      };
      starstableMark = pkgs.fetchurl {
        url = "https://cms-proxy.starstable.com/65346/1648052887-ssom.webp";
        hash = "sha256-aK577WDj7dJSAP+6f8mmzdqowM4PCZpcw+xewjGzg9g=";
      };

      # What HoYoPlay itself shows for Genshin, from its launcher API
      # (hyp-connect getGames, hk4e_global): background, logo and icon.
      genshinBackground = pkgs.fetchurl {
        url = "https://fastcdn.hoyoverse.com/static-resource-v2/2026/09/12/544bf0d17e4570f886fd1b731a3274da_5003849349598617917.webp";
        hash = "sha256-91F1ckny2bxoOMTmOHjdexmmXcbb4e9VHFzajn17GQI=";
      };
      genshinLogo = pkgs.fetchurl {
        url = "https://fastcdn.hoyoverse.com/static-resource-v2/2026/03/30/ee8f064a6d814f521c401f9778ce0b2f_1125309761890426348.png";
        hash = "sha256-yZhNKv1uJf2USM+oGwwwbjSF42BRLksUaLDICPjpWO8=";
      };
      genshinIcon = pkgs.fetchurl {
        url = "https://fastcdn.hoyoverse.com/static-resource-v2/2026/09/14/d76a4a6df4220cde1f434ca696824ccb_2101223399950486130.png";
        hash = "sha256-KuBPQR+nUk1bMJLaoHxAMj8byq9CAtj0SRAPEYOGQOw=";
      };
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
          extraPkgs = pkgs: [
            pkgs.gamemode
            pkgs.faudio
          ];
          extraLibraries = pkgs: [ pkgs.gamemode ];
        };
        gameWrappers = gameWrappers pkgs;
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-cachyos_x86_64_v3
        ];

        # Merged into steam's own config when it starts. proton-ge-bin renames its tool
        # to plain "GE-Proton", so the name survives version bumps.
        apps = {
          # The standalone launcher, not the Steam release. It is an electron-builder
          # installer, and under Proton it installs for all users, into Program Files -
          # not per-user, which is electron-builder's usual default.
          starstable = {
            shortcut.appName = "Star Stable Online";
            compatTool = "GE-Proton";
            installer = {
              url = "https://launcher-release-prod.starstable.com/latest/Star%20Stable%20Online%20Setup.exe";
              game = "drive_c/Program Files/Star Stable Online/Star Stable Online.exe";
            };
            # There is no logo with a transparent background, so no `logo`, and the
            # mark goes at the foot of the grid, where it covers leaves, not the horse.
            artwork = {
              grid = art {
                name = "starstable-grid";
                src = starstableKey;
                size = "600x900";
                over = {
                  src = starstableMark;
                  width = "220";
                  gravity = "south";
                };
              };
              wide = art {
                name = "starstable-wide";
                src = starstableKey;
                size = "920x430";
              };
              hero = art {
                name = "starstable-hero";
                src = starstableKey;
                size = "1920x620";
              };
              icon = art {
                name = "starstable-icon";
                src = starstableMark;
              };
            };
          };

          # HoYoPlay, HoYoverse's launcher, installed from Genshin's installer. Genshin, and
          # any other HoYoverse game added in it, is downloaded into this same prefix and
          # started from it. Its files sit in a folder named for its version, so this is
          # the launcher stub at the top, which stays put across updates. The attribute
          # name is the prefix's directory, so renaming it orphans the install.
          hoyoplay = {
            shortcut.appName = "HoYoPlay";
            compatTool = "GE-Proton";
            # Empty rather than unset: an unset option leaves Steam's last value in place,
            # and this was carrying PROTON_LOG from debugging Genshin's crashes.
            launchOptions = "";
            installer = {
              url = "https://download-porter.hoyoverse.com/download-porter/2026/10/13/GenshinImpact_install_20260924_hoyoverse.exe";
              game = "drive_c/Program Files/HoYoPlay/launcher.exe";
            };
            # Genshin's, since that is what it is here for.
            artwork = {
              grid = art {
                name = "genshin-grid";
                src = genshinBackground;
                size = "600x900";
                over = {
                  src = genshinLogo;
                  width = "480";
                  gravity = "south";
                };
              };
              wide = art {
                name = "genshin-wide";
                src = genshinBackground;
                size = "920x430";
              };
              hero = art {
                name = "genshin-hero";
                src = genshinBackground;
                size = "1920x620";
              };
              logo = genshinLogo;
              icon = genshinIcon;
            };
          };
        };
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
