{
  flake.modules.nixos.niri = {
    config,
    pkgs,
    ...
  }: let
    image = config.systemConstants.bg_img;
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.niri.settings = {
        spawn-at-startup = [
          {command = ["${pkgs.swaybg}/bin/swaybg" "-i" image "-m" "fill"];}
        ];
        layer-rules = [
          {
            matches = [{namespace = "^swaybg$";}];
            place-within-backdrop = true;
          }
        ];
      };
    };
  };
}
