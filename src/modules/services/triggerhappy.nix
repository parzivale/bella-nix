{inputs, ...}: {
  flake.modules.nixos.triggerhappy = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
    uid = toString config.systemConstants.uid;
    runtime = "XDG_RUNTIME_DIR=/run/user/${uid}";
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
  in {
    services.triggerhappy = {
      enable = true;
      user = user;
      bindings = [
        {
          keys = ["VOLUMEUP"];
          cmd = "${runtime} ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        }
        {
          keys = ["VOLUMEDOWN"];
          cmd = "${runtime} ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        }
        {
          keys = ["MUTE"];
          cmd = "${runtime} ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        }
      ];
    };
  };
}
