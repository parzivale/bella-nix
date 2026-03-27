{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    image = config.systemConstants.bg_img;
    user = config.systemConstants.username;
    blurred-image = pkgs.runCommand "blurred-wallpaper.png" {} ''
      ${pkgs.imagemagick}/bin/magick "${image}" -blur 0x8 $out
    '';
  in {
    home-manager.users.${user} = {
      programs.niri.settings = {
        layer-rules = [
          {
            matches = [{namespace = "swww-daemonoverview$";}];
            place-within-backdrop = true;
          }
        ];
        spawn-at-startup = [
          {command = ["sh" "-c" "while ! ${pkgs.swww}/bin/swww query 2>/dev/null; do sleep 0.1; done; ${pkgs.swww}/bin/swww img -t none ${image}"];}
          {command = ["sh" "-c" "while ! ${pkgs.swww}/bin/swww query -n overview 2>/dev/null; do sleep 0.1; done; ${pkgs.swww}/bin/swww img -t none -n overview ${blurred-image}"];}
        ];
      };
      systemd.user.services = {
        swww = {
          Unit = {
            After = ["graphical-session.target" "niri.service"];
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
            After = ["graphical-session.target" "niri.service"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${pkgs.swww}/bin/swww-daemon -n overview";
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
