{
  pkgs,
  vars,
  ...
}: {
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";
  programs.ssh.startAgent = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.domain = true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.userServices = true;
}
