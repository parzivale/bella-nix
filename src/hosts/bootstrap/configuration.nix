{vars, ...}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
  };

  system.stateVersion = "25.11";
}
