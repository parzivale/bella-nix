{
  pkgs,
  vars,
  lib,
  ...
}: let
  key = builtins.readFile ./ssh_host_ed25519_key.pub;
  user = vars.username;
in {
  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";
  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  environment.systemPackages = with pkgs; [
    age
    age-plugin-fido2-hmac
  ];

  programs = {
    git.enable = true;
  };

  home-manager.users.${user}.programs = {
    helix.enable = true;
    niri.enable = true;
  };

  services.getty.autologinUser = user;
  programs.ssh.startAgent = true;
}
