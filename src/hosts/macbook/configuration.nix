{inputs}: {
  config,
  lib,
  pkgs,
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
    cli
    deployer
    desktop
    workstation
    # hardware
    iwd
    zram
    # power
    batsignal
    hibernation
    # chat
    iamb
    # system
    avahi
    systemd-boot
    use-x86-builders
  ];
  # Allow x86_64 Wine runners to execute on ARM via FEX
  boot.binfmt.registrations.fex-x86_64 = {
    interpreter = "${pkgs.fex-headless}/bin/FEXInterpreter";
    magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
    mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
  };

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 24576;
      priority = 1;
    }
  ]; # 24GB

  boot.resumeDevice = "/dev/nvme0n1p5";
  boot.kernelParams = ["resume_offset=5847340"];

  system.stateVersion = "25.11";

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;

  home-manager.users.${user} = {pkgs, ...}: {
    home = {
      stateVersion = "25.11";
      packages = [pkgs.brightnessctl];
    };

    programs.niri.settings.input.touchpad.scroll-factor = 0.5;

    programs.niri.settings.binds = {
      "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "5%+"];
      "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
      "XF86KbdBrightnessUp".action.spawn = ["brightnessctl" "-d" "apple::kbd_backlight" "set" "5%+"];
      "XF86KbdBrightnessDown".action.spawn = ["brightnessctl" "-d" "apple::kbd_backlight" "set" "5%-"];
    };
  };
}
