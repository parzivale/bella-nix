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
      niri = pkgs.niri-unstable.override { withSystemd = false; };
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
        # For `session.command` below. The session's daemons are units rather than
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
          command = "${config.session.command} ${niri}/bin/niri --session";
          inherit user;
        };
      };

      # Two things have no finix counterpart and are dropped rather than faked:
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
