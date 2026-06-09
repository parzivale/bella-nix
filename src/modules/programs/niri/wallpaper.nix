{
  flake.modules.homeManager.niri =
    { pkgs, osConfig, ... }:
    let
      image = osConfig.systemConstants.bg_img;
      blurred-image = pkgs.runCommand "blurred-wallpaper.png" { } ''
        ${pkgs.imagemagick}/bin/magick "${image}" -blur 0x8 $out
      '';
    in
    {
      programs.niri.settings = {
        layer-rules = [
          {
            matches = [ { namespace = "awww-daemonoverview$"; } ];
            place-within-backdrop = true;
          }
        ];
      };
      systemd.user.services = {
        awww = {
          Unit = {
            After = [
              "graphical-session.target"
              "niri.service"
            ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.awww}/bin/awww-daemon";
            ExecStartPost = "${pkgs.bash}/bin/bash -c 'while ! ${pkgs.awww}/bin/awww query 2>/dev/null; do sleep 0.1; done; ${pkgs.awww}/bin/awww img -t none ${image}'";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        awww-overview = {
          Unit = {
            Description = "awww overview daemon";
            After = [
              "graphical-session.target"
              "niri.service"
            ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.awww}/bin/awww-daemon -n overview";
            ExecStartPost = "${pkgs.bash}/bin/bash -c 'while ! ${pkgs.awww}/bin/awww query -n overview 2>/dev/null; do sleep 0.1; done; ${pkgs.awww}/bin/awww img -t none -n overview ${blurred-image}'";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
