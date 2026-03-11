{inputs, ...}: {
  flake.modules.nixos.ddcutil = {
    pkgs,
    ...
  }: let
    ddcutil = "${pkgs.ddcutil}/bin/ddcutil";
  in {
    hardware.i2c.enable = true;
    environment.systemPackages = [pkgs.ddcutil];

    services.triggerhappy.bindings = [
      { keys = ["BRIGHTNESSUP"];   cmd = "${ddcutil} --noverify setvcp 10 + 5"; }
      { keys = ["BRIGHTNESSDOWN"]; cmd = "${ddcutil} --noverify setvcp 10 - 5"; }
    ];
  };
}
