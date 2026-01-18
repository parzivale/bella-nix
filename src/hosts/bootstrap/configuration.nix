{
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
  };

  environment.systemPackages = [pkgs.nixos-facter pkgs.age pkgs.age-plugin-fido2-hmac];

  system.stateVersion = "25.11";
}
