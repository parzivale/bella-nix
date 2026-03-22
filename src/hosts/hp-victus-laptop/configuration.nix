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
    _1password
    bluetooth
    claude
    cli
    ddcutil
    deployer
    desktop
    discord
    earlyoom
    nvidia
    osu
    pipewire
    spotify-player
    prismlauncher
    steam
    zram
    karere
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.xserver.xkb.layout = "us";

  system.stateVersion = "25.05";
  home-manager.users.${config.systemConstants.username}.home.stateVersion = "25.11";
}
