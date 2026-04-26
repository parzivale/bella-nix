{...}: {
  flake.modules.nixos.swayidle = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = let
      lock_command = "${pkgs.swaylock-effects}/bin/swaylock -f --clock --fade-in 1";
    in {
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 180;
            command = lock_command;
          }
          {
            timeout = 300;
            command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
            resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
          }
        ];
        events = {
          before-sleep = lock_command;

          lock = lock_command;
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
  };
}
