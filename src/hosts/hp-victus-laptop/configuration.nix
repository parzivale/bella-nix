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
    localization
    niri
    wezterm
    stylix
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

  system.stateVersion = "25.05";
  home-manager.users.${config.vars.username}.home.stateVersion = "25.11";
}
