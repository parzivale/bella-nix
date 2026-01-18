{
  pkgs,
  vars,
  ...
}: {
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
}
