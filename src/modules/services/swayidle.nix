{inputs, ...}: {
  flake.modules.homeManager.swayidle = {pkgs, ...}: let
    lock_service = "${pkgs.systemd}/bin/systemctl --user start swaylock.service";
  in {
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
        after-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
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

  flake.modules.nixos.swayidle = {config, pkgs, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.swayidle];

    systemd.user.services.swaylock = {
      description = "Screen locker";
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.swaylock-effects}/bin/swaylock --clock --fade-in 1";
        Restart = "no";
      };
    };
  };
}
