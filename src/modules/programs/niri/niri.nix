{ inputs, ... }:
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

      nixpkgs.overlays = [
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
}
