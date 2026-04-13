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
            matches = [{namespace = "awww-daemonoverview$";}];
            place-within-backdrop = true;
          }
        ];
        spawn-at-startup = [
          {command = ["sh" "-c" "while ! ${pkgs.awww}/bin/awww query 2>/dev/null; do sleep 0.1; done; ${pkgs.awww}/bin/awww img -t none ${image}"];}
          {command = ["sh" "-c" "while ! ${pkgs.awww}/bin/awww query -n overview 2>/dev/null; do sleep 0.1; done; ${pkgs.awww}/bin/awww img -t none -n overview ${blurred-image}"];}
        ];
      };
      systemd.user.services = {
        awww = {
          Unit = {
            After = ["graphical-session.target" "niri.service"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${pkgs.awww}/bin/awww-daemon";
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };

        awww-overview = {
          Unit = {
            Description = "awww overview daemon";
            After = ["graphical-session.target" "niri.service"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${pkgs.awww}/bin/awww-daemon -n overview";
            Restart = "on-failure";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
