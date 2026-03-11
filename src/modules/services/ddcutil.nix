{inputs, ...}: {
  flake.modules.nixos.ddcutil = {
    config,
    pkgs,
    ...
  }: let
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  in {
    hardware.i2c.enable = true;
    boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
    boot.kernelModules = ["ddcci_backlight"];

    services.triggerhappy.bindings = [
      { keys = ["BRIGHTNESSUP"];   cmd = "${brightnessctl} -c ddcci set 5%+"; }
      { keys = ["BRIGHTNESSDOWN"]; cmd = "${brightnessctl} -c ddcci set 5%-"; }
    ];
  };
}
