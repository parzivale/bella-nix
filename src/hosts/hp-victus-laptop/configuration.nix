{
  self,
  pkgs,
  vars,
  lib,
  ...
}: let
  path = ./ssh_host_ed25519_key.pub;
  key =
    if builtins.pathExists path
    then builtins.readFile path
    else "";
in {
  inputs = with self.modules.bella; [
    helix
    git
    ssh
    localization
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

  programs = {
    niri.enable = true;
  };

  system.stateVersion = "25.05";
  home-manager.users.${vars.username} = {
    home = {
      stateVersion = "25.11";
      packages = with pkgs; [
        age
        age-plugin-fido2-hmac
      ];
    };
    programs = {
      helix.enable = true;
      git.enable = true;
      nh.enable = true;
      ssh.enable = true;
    };
  };
}
