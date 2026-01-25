{
  pkgs,
  vars,
  ...
}: {
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";
  programs.ssh.startAgent = true;
}
