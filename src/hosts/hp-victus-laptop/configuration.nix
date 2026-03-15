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
    bluetooth
    claude
    cli
    ddcutil
    deployer
    desktop
    discord
    osu
    prismlauncher
    steam
    zram
    karere
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services = {
    xserver.xkb.layout = "us";
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };

  # Boot speed up
  boot.blacklistedKernelModules = ["serial_8250"];
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [];

  system.stateVersion = "25.05";
  home-manager.users.${config.systemConstants.username}.home.stateVersion = "25.11";
}
