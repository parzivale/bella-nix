{inputs, ...}: {
  flake.modules.nixos.triggerhappy = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    services.triggerhappy = {
      enable = true;
      user = user;
      bindings = [
        { keys = ["KEY_BRIGHTNESSUP"];   cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+"; }
        { keys = ["KEY_BRIGHTNESSDOWN"]; cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-"; }
        { keys = ["KEY_VOLUMEUP"];       cmd = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; }
        { keys = ["KEY_VOLUMEDOWN"];     cmd = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
        { keys = ["KEY_MUTE"];           cmd = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
      ];
    };
  };
}
