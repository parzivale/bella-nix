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
        # The user's service tree and what starts it. finix's niri session entry runs the
        # contract's launcher when there is a tree, so this is where the session's daemons come
        # from - and its bus, and its log.
        inputs.self.modules.finix.user-services
      ];

      nixpkgs.overlays = overlays;

      programs.niri = {
        enable = true;
        package = niri;
      };

      # tuigreet, offering the sessions installed on the system - finix's niri entry, which goes
      # through the session launcher and so starts the bus, the user's tree and the log relay
      # along with the compositor. Nothing about the session is spelled out here any more.
      #
      # `user` is left at finix's `greeter`: naming bella here is what made this an autologin,
      # and a greeter is the point. Which also retires the edge this used to carry from greetd
      # to `hm-activate-bella` - it existed because an autologin raced home-manager to niri's
      # config, and a password typed at a greeter does not win that race. It was a hard edge, too:
      # a failed activation meant no greeter at all.
      services.greetd = {
        enable = true;
        settings.default_session.command = lib.escapeShellArgs [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--remember-session"
          "--sessions"
          "/run/current-system/sw/share/wayland-sessions"
        ];
      };

      # No gettys beside the greeter. greetd's `terminal.vt` is "next", the first console
      # nobody has opened, and the gettys on tty1 through tty6 start in the same tier as
      # greetd - so when greetd won, it took a console a getty then opened too, and the two
      # read the keyboard between them: typing into tuigreet lost and mangled characters.
      # What goes with them is a text login for when the session will not start; ssh over
      # tailscale is the way in then.
      services.getty.enable = false;

      # The polkit agent, which niri-flake's nixos module supplies as
      # `niri-flake-polkit` and which nothing supplies here. Without one a polkit
      # question has nobody to ask: 1Password's three actions are all `auth_self`,
      # so unlocking with system authentication, authorising the `op` CLI and
      # authorising its ssh agent each fail outright rather than prompting. `pkexec`
      # is the other caller, since finix installs its setuid wrapper whenever polkit
      # is on.
      #
      # finix's now, in every user's session tree: which agent (polkit-gnome, not soteria) and
      # which polkit it has to be built against (the elogind one) are its to know, beside the
      # helper wrapper it installs. See `services.polkit.agent` there.
      services.polkit.agent.enable = true;

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

          # And the stylix target, from the same injection and lost for the same reason. It is
          # niri-flake's, not stylix's - so it is not among stylix's own targets and cannot be
          # enabled from there - and the nixos module adds it only when both a home-manager and a
          # stylix option exist in that evaluation:
          #
          #   ++ lib.optionals (options ? stylix) [ self.homeModules.stylix ]
          #
          # Without it niri used niri-flake's defaults, theme "default" at size 24 and no border
          # colour, while gtk applications read Nordzy-cursors at 32 out of settings.ini: a cursor
          # of the right shape and the wrong size, and borders that had quietly lost their accent.
          #
          # Named on this branch only. The option it declares is also declared by stylix's nixos
          # module, which mirrors targets into home-manager - so naming it in the shared home
          # module breaks every nixos host with "already declared", which is how this was found.
          inputs.niri-flake.homeModules.stylix

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
