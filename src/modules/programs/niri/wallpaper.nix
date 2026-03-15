{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    image = config.systemConstants.bg_img;
    user = config.systemConstants.username;
    waitForSwww = pkgs.writeShellScript "wait-for-swww" ''
      timeout=5
      elapsed=0
      while ! ${pkgs.swww}/bin/swww query $@ &>/dev/null; do
        sleep 0.1
        elapsed=$(echo "$elapsed + 0.1" | ${pkgs.bc}/bin/bc)
        if [ "$(echo "$elapsed >= $timeout" | ${pkgs.bc}/bin/bc)" -eq 1 ]; then
          exit 1
        fi
      done
    '';
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
            ExecStart = "${pkgs.swww}/bin/swww-daemon";
            Restart = "on-failure";
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
            ExecStart = "${pkgs.swww}/bin/swww-daemon -n overview";
            Restart = "on-failure";
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
            ExecStartPre = "${waitForSwww}";
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
            ExecStartPre = "${waitForSwww} -n overview";
            ExecStart = "${pkgs.swww}/bin/swww img -t none -n overview ${image}";
            RemainAfterExit = true;
          };
          Install.WantedBy = ["graphical-session.target" "sleep.target"];
        };
      };
    };
  };
}
