{
  pkgs,
  vars,
  ...
}: {
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";

  age.rekey.hostPubkey = builtins.readFile ./ssh_host_ed25519_key;

  programs.ssh.startAgent = true;
}
