{ inputs, ... }:
{
  flake.modules.homeManager.swayidle =
    { pkgs, ... }:
    let
      lock_service = "${pkgs.systemd}/bin/systemctl --user start swaylock.service";
      after_resume = pkgs.writeShellScript "swayidle-after-resume" ''
        ${pkgs.niri}/bin/niri msg action power-on-monitors
        while ! ${pkgs.niri}/bin/niri msg --json outputs | ${pkgs.gnugrep}/bin/grep -q '"logical":{'; do
          sleep 0.1
        done
        ${pkgs.systemd}/bin/systemctl --user restart awww.service awww-overview.service
      '';
    in
    {
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 180;
            command = lock_service;
          }
          {
            timeout = 300;
            command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
            resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
          }
        ];
        events = {
          before-sleep = lock_service;
          after-resume = "${after_resume}";
          lock = lock_service;
        };
      };

      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          show-failed-attempts = true;
          indicator-idle-visible = true;
        };
      };
    };

  flake.modules.nixos.swayidle =
    { config, pkgs, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [
        inputs.self.modules.nixos.home-manager
        # `pkgs.niri` below comes from niri-flake's overlay, which niri.nix owns.
        inputs.self.modules.nixos.niri
      ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.swayidle ];

      systemd.user.services.swaylock = {
        description = "Screen locker";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.swaylock-effects}/bin/swaylock --clock --fade-in 1";
          Restart = "no";
        };
      };
    };

  # swayidle itself carries over; what it is told to run does not, because every
  # one of those commands was `systemctl --user`.
  #
  #   The lock was a user service so that two triggers - a timeout and
  #   before-sleep - converge on one swaylock rather than two. `swaylock -f`
  #   twice would be two, so the script below is the part of the service that
  #   mattered: it does nothing if one is already up.
  #
  #   after-resume restarted the wallpaper daemons. That is not sayable portably -
  #   `providers.services` exposes no start/stop/restart - so the daemons are
  #   killed and the supervisor brings them back, which works because each unit
  #   re-applies its image on start. See `niri/wallpaper.nix`.
  #
  # `swaylock.enable` in home-manager is what writes ~/.config/swaylock/config, so
  # the settings still come from the home half; only the unit is dropped.
  flake.modules.finix.swayidle =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.constants.username;

      # The niri that is running, not nixpkgs' - `niri msg` speaks an IPC whose
      # schema moves with the compositor, so a different build's `msg` is a
      # different protocol. The nixos half of this module says `pkgs.niri` and has
      # the same mismatch; it is left alone here rather than changed in passing.
      niri = lib.getExe config.programs.niri.package;

      # `-f` so swayidle is not blocked waiting for the screen to unlock, and the
      # guard so a second trigger does not stack a second locker on the first.
      lock = pkgs.writeShellScript "lock" ''
        set -eu

        if ${pkgs.procps}/bin/pgrep -x swaylock > /dev/null; then
          exit 0
        fi

        exec ${pkgs.swaylock-effects}/bin/swaylock --clock --fade-in 1 -f
      '';

      after_resume = pkgs.writeShellScript "swayidle-after-resume" ''
        set -eu

        ${niri} msg action power-on-monitors

        while ! ${niri} msg --json outputs | ${pkgs.gnugrep}/bin/grep -q '"logical":{'; do
          ${pkgs.coreutils}/bin/sleep 0.1
        done

        # Killed rather than restarted, the supervisor being the thing that starts
        # it again - and each awww unit sets its image as it comes up, so the
        # wallpaper returns with the daemon.
        ${pkgs.procps}/bin/pkill -x awww-daemon || true
      '';
    in
    {
      imports = [
        inputs.self.modules.finix.graphical-session
        inputs.self.modules.finix.home-manager
        inputs.self.modules.finix.niri
      ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.swayidle ];

      state.session.services.swayidle = {
        description = "idle manager";

        command = [
          "${pkgs.swayidle}/bin/swayidle"
          "-w"
          "timeout"
          "180"
          "${lock}"
          "timeout"
          "300"
          "${niri} msg action power-off-monitors"
          "resume"
          "${niri} msg action power-on-monitors"
          "before-sleep"
          "${lock}"
          "lock"
          "${lock}"
          "after-resume"
          "${after_resume}"
        ];
      };
    };
}
