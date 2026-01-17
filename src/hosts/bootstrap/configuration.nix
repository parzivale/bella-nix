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

  environment.systemPackages = [pkgs.nixos-facter];

  age.rekey.hostPubkey = ./bootstrap_key.pub;

  system.stateVersion = "25.11";
}
