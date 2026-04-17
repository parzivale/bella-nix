{inputs, ...}: {
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    imports = [
      inputs.niri-flake.nixosModules.niri
    ];

    # autolaunch niri

    services = {
      greetd = {
        enable = true;
        settings.default_session = {
          command = "niri-session";
          user = user;
        };
      };
      dbus = {
        enable = true;
        implementation = "broker";
      };
    };

    services.getty.autologinUser = user;
    programs.niri.enable = true;

    home-manager.users.${user} = {
      config,
      pkgs,
      lib,
      ...
    }: {
      programs.niri = {
        package = pkgs.niri-unstable;
        settings = {
          xwayland-satellite = {
            enable = true;
            path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          };

          prefer-no-csd = true;

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
  };
}
