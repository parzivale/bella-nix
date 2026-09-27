{ inputs, ... }:
let
  overlays = [
    # niri-flake (as of rev 9ee3e13) still builds against libdisplay-info_0_2,
    # which nixpkgs removed. niri's libdisplay-info-sys crate pins the pkg-config
    # library to >=0.1.0, <0.3.0, so 0.3+ won't do — pull the real 0.2 package
    # from a pinned pre-removal nixpkgs.
    (final: prev: {
      libdisplay-info_0_2 =
        (import inputs.nixpkgs-libdisplay-info {
          inherit (prev.stdenv.hostPlatform) system;
        }).libdisplay-info_0_2;
    })
    inputs.niri-flake.overlays.niri
  ];
in
{
  flake.modules.homeManager.niri =
    { config, pkgs, ... }:
    {
      # niri's stylix target, which lives in niri-flake rather than in stylix - so it is not one
      # of stylix's own targets and cannot be enabled from there. niri-flake's nixos module wires
      # it in, conditionally:
      #
      #   (lib.optionalAttrs (options ? home-manager) {
      #     home-manager.sharedModules = [ ... ]
      #       ++ lib.optionals (options ? stylix) [ self.homeModules.stylix ];
      #   })
      #
      # Neither condition holds in a finix evaluation, so the target was absent and niri used
      # niri-flake's own defaults - theme "default" at size 24, no border colour - while every
      # gtk application read Nordzy-cursors at 32 out of settings.ini. A cursor of the right shape
      # and the wrong size, and window borders that had quietly lost their accent.
      #
      # Named here rather than beside the other stylix imports, because it writes
      # `programs.niri.settings`: it belongs with the module that makes those options exist, not
      # with the one that supplies the colours. On nixos the same module arrives through
      # `sharedModules` as well, and importing a module twice is importing it once.
      imports = [ inputs.niri-flake.homeModules.stylix ];

      programs.niri = {
        settings = {
          xwayland-satellite = {
            enable = true;
            path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          };

          prefer-no-csd = true;

          debug = {
            disable-direct-scanout = true;
          };

          screenshot-path = "${config.xdg.userDirs.pictures}/Screenshot from %Y-%m-%d %H-%M-%S.png";

          layout = {
            empty-workspace-above-first = true;
          };

          input = {
            mouse.accel-profile = "flat";
            touchpad.tap = false;

            focus-follows-mouse = {
              enable = true;
              max-scroll-amount = "0%";
            };
            warp-mouse-to-focus = {
              enable = true;
              mode = "center-xy";
            };
          };

          outputs = {
            HDMI-A-1 = {
              variable-refresh-rate = true;
              focus-at-startup = true;
              mode = {
                width = 2560;
                height = 1440;
                refresh = 143.912;
              };
              position = {
                x = 0;
                y = 0;
              };
            };
          };
        };
      };
    };

  flake.modules.nixos.niri =
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
        inputs.niri-flake.nixosModules.niri
        inputs.self.modules.nixos.home-manager
      ];

      nixpkgs.overlays = overlays;

      services = {
        greetd = {
          enable = true;
          settings.default_session = {
            command = "niri-session";
            inherit user;
          };
        };
        dbus = {
          enable = true;
          implementation = "broker";
        };
      };

      services.getty.autologinUser = user;
      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.niri ];
    };

  flake.modules.finix.niri =
    {
      config,
      pkgs,
      lib,
      modules,
      ...
    }:
    let
      user = config.constants.username;

      # `withSystemd` off, which is not about linking: niri's systemd feature puts
      # anything it spawns - the `spawn` action, `spawn-at-startup` - into a
      # transient unit, so that an OOM kill takes the process rather than the whole
      # session. Creating one means asking a systemd manager, and there is none
      # here. Without the feature niri spawns the process itself, which is the
      # behaviour to want when nothing is going to answer.
      #
      # niri-flake's postFixup unconditionally `substituteInPlace`s
      # $out/lib/systemd/user/niri.service, but postInstall only creates that
      # file when withSystemd is on - so with it off (and withDinit off, the
      # default) the build crashes patching a file that was never installed.
      # We don't want that unit anyway with no systemd here, so drop postFixup.
      niri = (pkgs.niri-unstable.override { withSystemd = false; }).overrideAttrs (_: {
        postFixup = "";
      });
    in
    {
      imports = [
        # finix's own niri, not niri-flake's nixos module: both declare
        # `programs.niri.enable`, and niri-flake's builds a systemd user session.
        # The settings still come from niri-flake, through its home module below -
        # that half is `xdg.configFile`, which the home-manager port supports.
        modules.niri
        modules.greetd
        # libinput enumerates input devices through udev, so a compositor
        # without it has no keyboard. finix leaves it off by default.
        inputs.self.modules.finix.udev
        inputs.self.modules.finix.home-manager
        inputs.self.modules.finix.user
        # For `state.session.command` below. The session's daemons are units rather than
        # things niri spawns, so what niri owes them is a bus whose address they can
        # find - which is what that script arranges.
        inputs.self.modules.finix.graphical-session
      ];

      nixpkgs.overlays = overlays;

      programs.niri = {
        enable = true;
        package = niri;
      };

      services.greetd = {
        enable = true;
        settings.default_session = {
          # Not `niri-session`: niri-flake says of that script that it "only works
          # with systemd or dinit", and finit is neither.
          command = "${config.state.session.command} ${niri}/bin/niri --session";
          inherit user;
        };
      };

      # greetd waits for the user's home to be set up.
      #
      # Without this they start together - `hm-activate-bella` and `greetd` in the same second,
      # `greetd-started` immediately after - so the compositor reads its configuration while
      # home-manager is still linking it, finds nothing, and falls back to the built-in default
      # config. Whose terminal keybind names a terminal this machine does not install, so the
      # session comes up with no configuration and no way to open a shell in it. On a laptop
      # whose function keys are drawn by a daemon that also is not running yet, that is the whole
      # machine.
      #
      # `requires` is the only ordering the contract has, so this is a hard edge: if activation
      # fails, no session starts at all. That is the right way round - a session with none of the
      # user's configuration is not a working machine either - but it does mean sshd is the way
      # back in, which is why it does not depend on any of this.
      providers.services.units.greetd.requires = [ "hm-activate-${user}" ];

      # The polkit agent, which niri-flake's nixos module supplies as
      # `niri-flake-polkit` and which nothing supplies here. Without one a polkit
      # question has nobody to ask: 1Password's three actions are all `auth_self`,
      # so unlocking with system authentication, authorising the `op` CLI and
      # authorising its ssh agent each fail outright rather than prompting. `pkexec`
      # is the other caller, since finix installs its setuid wrapper whenever polkit
      # is on.
      #
      # polkit-gnome rather than soteria, which this used and which never once ran.
      # soteria reimplements the agent protocol and hardcodes the helper's path:
      #
      #   Error: Helper located at /usr/lib/polkit-1/polkit-agent-helper-1 and socket
      #   located at /run/polkit/agent-helper.socket do not exist.
      #
      # Neither path exists here - the helper is a setuid wrapper at
      # /run/wrappers/bin/polkit-agent-helper-1 - so it exited 1 before contacting
      # polkit at all, on this machine as much as in a VM. polkit-gnome goes through
      # libpolkit-agent-1, which nixpkgs patches to call exactly that wrapper, so it
      # needs nothing said here to find it.
      #
      # `libexec` rather than `lib.getExe`: the agent is not on the package's PATH
      # and the package declares no main program.
      #
      # community-modules has a soteria module and this does not use it: that one
      # emits a system unit, and an agent which shows a dialog has to be inside the
      # session and on its bus. So the package, started the way the session's other
      # daemons are.
      state.session.services.polkit-agent = {
        description = "polkit authentication agent";

        # The agent built against the polkit the daemon uses, not against `pkgs.polkit`.
        #
        # finix overrides `services.polkit.package` to the elogind build - its own note says
        # `loginctl poweroff` needs it - but that option reaches the daemon and nothing else. An
        # agent links libpolkit itself, and `pkgs.polkit_gnome` takes plain `pkgs.polkit`, whose
        # `useSystemd` defaults to true on Linux. So it was built `-Dsession_tracking=logind` and
        # asked systemd's `sd_pid_get_session`, which looks for a cgroup path like
        # /user.slice/user-1000.slice/session-1.scope; elogind's are flat, /1, so every process
        # on the machine got
        #
        #   polkit-gnome-1-WARNING: Unable to determine the session we are in: No session for pid
        #
        # and no polkit prompt has ever appeared here. The same call compiled against each build:
        # `pkgs.polkit` answers "No session for pid", the elogind one answers "unix-session:1".
        #
        # Overriding this one package rather than `pkgs.polkit` globally, which is the same fix
        # and rebuilds everything that links polkit - udisks, the portals, colord, most of the
        # gtk-adjacent world - to correct an agent.
        command = [
          "${
            pkgs.polkit_gnome.override { polkit = config.services.polkit.package; }
          }/libexec/polkit-gnome-authentication-agent-1"
        ];
      };

      #
      #   `services.dbus.implementation = "broker"` — finix's dbus module runs
      #   `${package}/bin/dbus-daemon`, a path dbus-broker does not have, so
      #   choosing it is not a matter of setting `package`. Wiring broker up there
      #   is real work with a real question behind it: activation goes through
      #   systemd, which is the thing that is not here.
      #
      #   `services.getty.autologinUser` — greetd already starts the session with
      #   no prompt, so what is lost is logging in on the text consoles.
      #   `services.autologin` is what would provide it, and wants a command.

      home-manager.users.${user} = {
        imports = [
          # niri-flake's nixos module injects this into home-manager itself, so the
          # nixos branch never names it. Without that module there is nothing doing
          # the injecting, and `programs.niri` does not exist home-side at all.
          inputs.niri-flake.homeModules.niri
          inputs.self.modules.homeManager.niri
        ];

        # The other half of what that injection does. The home module validates the
        # generated KDL by running this niri against it, so a package that is not
        # the one being run validates against the wrong grammar - which it did: it
        # defaulted to niri 25.08 and rejected `debug { disable-direct-scanout }`,
        # a key that release does not have.
        programs.niri.package = niri;
      };
    };
}
