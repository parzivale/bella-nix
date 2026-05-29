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
    deployable
    desktop
    remote-builder
    # GPU + monitor control
    nvidia
    ddcutil
    # gaming
    discord
    osu
    steam
    sober
    # system
    zram
    use-arm-builders
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 24576;
      priority = 1;
    }
  ]; # 24GB

  nix.settings.extra-platforms = ["i686-linux"];

  services.xserver.xkb.layout = "us";

  system.stateVersion = "25.05";
  home-manager.users.${config.systemConstants.username}.home.stateVersion = "25.11";
}
