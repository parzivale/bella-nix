{
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
  time.timeZone = "Europe/Stockholm";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "sv_SE.UTF-8";
      LC_IDENTIFICATION = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_NAME = "sv_SE.UTF-8";
      LC_NUMERIC = "sv_SE.UTF-8";
      LC_PAPER = "sv_SE.UTF-8";
      LC_TELEPHONE = "sv_SE.UTF-8";
      LC_TIME = "sv_SE.UTF-8";
    };
  };

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
