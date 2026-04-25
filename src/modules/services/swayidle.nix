{...}: {
  flake.modules.nixos.swayidle = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 300;
            command = "${pkgs.swaylock}/bin/swaylock -f";
          }
          {
            timeout = 600;
            command = "niri msg action power-off-monitors";
            resumeCommand = "niri msg action power-on-monitors";
          }
        ];
        events = {
          before-sleep = "${pkgs.swaylock}/bin/swaylock -f";

          lock = "${pkgs.swaylock}/bin/swaylock -f";
        };
      };

      programs.swaylock = {
        enable = true;
        settings = {
          show-failed-attempts = true;
          indicator-idle-visible = true;
        };
      };
    };
  };
}
