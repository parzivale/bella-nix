{inputs, ...}: {
  flake.modules.nixos.ddcutil = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
    ddcutil = "${pkgs.ddcutil}/bin/ddcutil";
  in {
    hardware.i2c.enable = true;

    home-manager.users.${user} = {config, ...}: {
      home.packages = [pkgs.ddcutil];

      programs.niri.settings.binds = {
        "XF86MonBrightnessUp".action.spawn = [ddcutil "setvcp" "10" "+" "5"];
        "XF86MonBrightnessDown".action.spawn = [ddcutil "setvcp" "10" "-" "5"];
      };
    };

    users.users.${user}.extraGroups = ["video" "i2c"];
  };
}
