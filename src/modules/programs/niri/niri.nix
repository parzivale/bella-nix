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

    # ddcci for external monitor brightness control
    hardware.i2c.enable = true;
    boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
    boot.kernelModules = ["ddcci_backlight"];

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
      home.packages = [pkgs.brightnessctl];

      programs.niri = {
        package = pkgs.niri-unstable;
        settings = let
          brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
          wpctl = "${pkgs.wireplumber}/bin/wpctl";
        in {
          binds = {
            "XF86AudioRaiseVolume".action.spawn = [wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
            "XF86AudioLowerVolume".action.spawn = [wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
            "XF86AudioMute".action.spawn = [wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
            "XF86MonBrightnessUp".action.spawn = [brightnessctl "-d" "ddcci9" "set" "5%+"];
            "XF86MonBrightnessDown".action.spawn = [brightnessctl "-d" "ddcci9" "set" "5%-"];
          };

          xwayland-satellite = {
            enable = true;
            path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          };

          input = {
            mouse.accel-profile = "flat";
            focus-follows-mouse.enable = true;
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
