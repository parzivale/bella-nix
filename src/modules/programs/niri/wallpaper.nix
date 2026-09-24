{ lib, ... }:
{
  flake.modules.homeManager.niri =
    { pkgs, osConfig, ... }:
    let
      image = osConfig.constants.bg_img;
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
            Environment = [ "PATH=${pkgs.awww}/bin:/run/current-system/sw/bin" ];
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
            Environment = [ "PATH=${pkgs.awww}/bin:/run/current-system/sw/bin" ];
            ExecStart = "${pkgs.awww}/bin/awww-daemon -n overview";
            ExecStartPost = "${pkgs.bash}/bin/bash -c 'while ! ${pkgs.awww}/bin/awww query -n overview 2>/dev/null; do sleep 0.1; done; ${pkgs.awww}/bin/awww img -t none -n overview ${blurred-image}'";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };

  # The two daemons again, as session units. What moves is not just the spelling:
  # the nixos units set the image with `ExecStartPost`, a second command run once
  # the first has started, and a unit here has one command. So each is a script
  # which arranges the image and then becomes the daemon.
  #
  # That ordering is deliberate rather than incidental. It makes the unit
  # self-contained, and self-contained is what makes a restart mean something:
  # kill the daemon, the supervisor starts it again, and the wallpaper comes back
  # with it. `providers.services` has no portable start/stop/restart - unlike
  # `providers.privileges`, which does expose its command - so "restart this"
  # cannot be said from a script without naming finit. Killing it can.
  flake.modules.finix.niri =
    { pkgs, config, ... }:
    let
      image = config.constants.bg_img;

      blurred-image = pkgs.runCommand "blurred-wallpaper.png" { } ''
        ${pkgs.imagemagick}/bin/magick "${image}" -blur 0x8 $out
      '';

      # `-n <name>` is how awww distinguishes its instances, so it is also how the
      # image is aimed at one. The wait is the ExecStartPost's, kept: `awww img`
      # before the daemon answers is an error rather than a retry.
      daemon =
        { name, wallpaper }:
        pkgs.writeShellScript "awww-${name}" ''
          set -eu

          # Quoted on assignment and unquoted on use, deliberately: the value is two
          # words when there is one at all, and nothing when there is not.
          instance="${lib.optionalString (name != "background") "-n ${name}"}"

          (
            until ${pkgs.awww}/bin/awww query $instance > /dev/null 2>&1; do
              ${pkgs.coreutils}/bin/sleep 0.1
            done
            exec ${pkgs.awww}/bin/awww img -t none $instance ${wallpaper}
          ) &

          exec ${pkgs.awww}/bin/awww-daemon $instance
        '';
    in
    {
      state.session.services = {
        awww = {
          description = "wallpaper daemon";
          command = [
            (toString (daemon {
              name = "background";
              wallpaper = image;
            }))
          ];
        };

        awww-overview = {
          description = "wallpaper daemon for the overview backdrop";
          command = [
            (toString (daemon {
              name = "overview";
              wallpaper = blurred-image;
            }))
          ];
        };
      };
    };
}
