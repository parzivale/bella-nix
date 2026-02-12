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
  home-manager.users.${vars.username} = {
    age.rekey.hostPubkey = lib.mkIf (key != "") key;
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

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;
}
