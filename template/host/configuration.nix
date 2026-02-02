{
  pkgs,
  vars,
  lib,
  ...
}: let
  key = builtins.readFile ./ssh_host_ed25519_key;
in {
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  programs.ssh.startAgent = true;
}
