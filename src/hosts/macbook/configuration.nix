{inputs}: {
  config,
  lib,
  ...
}: let
  path = ./ssh_host_ed25519_key.pub;
  key =
    if builtins.pathExists path
    then builtins.readFile path
    else "";
  user = config.systemConstants.username;
in {
  imports = with inputs.self.modules.nixos; [
    helix
    git
    ssh
    localization
    avahi
    systemd-boot
    deployer
    cli
    _1password
    claude
    desktop
    zram
    pipewire
    bluetooth
    iwd
  ];
  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;

  home-manager.users.${user} = {pkgs, ...}: {
    home.packages = [pkgs.brightnessctl];

    programs.niri.settings.binds = {
      "XF86MonBrightnessUp".action.spawn   = ["brightnessctl" "set" "5%+"];
      "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
      "XF86KbdBrightnessUp".action.spawn   = ["brightnessctl" "-d" "apple::kbd_backlight" "set" "5%+"];
      "XF86KbdBrightnessDown".action.spawn = ["brightnessctl" "-d" "apple::kbd_backlight" "set" "5%-"];
    };
  };
}
