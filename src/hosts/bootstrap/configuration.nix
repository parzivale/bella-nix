{
  vars,
  config,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
  };

  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = config.age.secrets.bootstrap_key.path;
    mode = "600";
    user = "root";
    group = "root";
  };

  environment.etc."ssh/ssh_host_ed25519_key.pub" = {
    source = ./bootstrap_key.pub;
    mode = "644";
    user = "root";
    group = "root";
  };

  environment.systemPackages = [pkgs.nixos-facter];

  age.rekey.hostPubkey = ./bootstrap_key.pub;

  system.stateVersion = "25.11";
}
