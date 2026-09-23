{ inputs, ... }:
{
  flake.modules.nixos.ddcutil =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
      ddcutil = "${pkgs.ddcutil}/bin/ddcutil";
    in
    {
      imports = [
        inputs.self.modules.nixos.user
        inputs.self.modules.nixos.home-manager
      ];

      hardware.i2c.enable = true;

      home-manager.users.${user}.home.packages = [ pkgs.ddcutil ];

      state.keybinds = {
        "XF86MonBrightnessUp" = [
          ddcutil
          "setvcp"
          "10"
          "+"
          "5"
        ];
        "XF86MonBrightnessDown" = [
          ddcutil
          "setvcp"
          "10"
          "-"
          "5"
        ];
      };

      users.users.${user}.extraGroups = [
        "video"
        "i2c"
      ];
    };
}
