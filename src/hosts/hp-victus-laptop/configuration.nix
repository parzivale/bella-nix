{
  pkgs,
  vars,
  ...
}: {
  # TODO copy over config from laptop
  system.stateVersion = "25.11";
  home-manager.users.${vars.username}.home.stateVersion = "25.11";
}
