{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    image = config.systemConstants.bg_img;
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.niri.settings.layer-rules = [
        {
          matches = [{namespace = "swww-daemonoverview$";}];
          place-within-backdrop = true;
        }
      ];
      systemd.user.services = {
        swww = {
          Unit = {
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.swww}/bin/swww init";
            ExecStop = "${pkgs.swww}/bin/swww kill";
          };
          Install.WantedBy = ["graphical-session.target"];
        };

        swww-overview = {
          Unit = {
            Description = "swww overview daemon";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.swww}/bin/swww init -n overview";
            ExecStop = "${pkgs.swww}/bin/swww kill -n overview";
          };
          Install.WantedBy = ["graphical-session.target"];
        };

        swww-set = {
          Unit = {
            Description = "Set swww wallpaper";
            After = ["swww.service" "graphical-session.target"];
            Requires = ["swww.service"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.swww}/bin/swww img -t none ${image}";
            RemainAfterExit = true;
          };
          Install.WantedBy = ["graphical-session.target" "sleep.target"];
        };

        swww-overview-set = {
          Unit = {
            Description = "Set swww overview wallpaper";
            After = ["swww-overview.service" "graphical-session.target"];
            Requires = ["swww-overview.service"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.swww}/bin/swww img -t none -n overview ${image}";
            RemainAfterExit = true;
          };
          Install.WantedBy = ["graphical-session.target" "sleep.target"];
        };
      };
    };
  };
}
