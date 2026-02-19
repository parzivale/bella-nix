{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    image = config.systemConstants.bg_img;
  in {
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
          ExecStart = "${pkgs.swww}/bin/swww img -t none ${image}";
          RemainAfterExit = true;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
