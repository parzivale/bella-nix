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
in {
  imports = with inputs.self.modules.nixos; [
    cli
    deployer
    desktop
    workstation
    # GPU + monitor control
    nvidia
    ddcutil
    # gaming
    osu
    steam
    sober
    # social
    discord
    karere
    # system
    avahi
    systemd-boot
    use-arm-builders
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 24576;
    }
  ]; # 24GB

  services.xserver.xkb.layout = "us";

  system.stateVersion = "25.05";
  home-manager.users.${config.systemConstants.username}.home.stateVersion = "25.11";
}
