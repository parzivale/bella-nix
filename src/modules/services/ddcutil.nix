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
    environment.systemPackages = [pkgs.ddcutil];

    home-manager.users.${user} = {config, ...}: {
      programs.niri.settings.binds = with config.lib.niri.actions; {
        "XF86MonBrightnessUp".action.spawn = [ddcutil "setvcp" "10" "+" "5"];
        "XF86MonBrightnessDown".action.spawn = [ddcutil "setvcp" "10" "-" "5"];
      };
    };
  };
}
