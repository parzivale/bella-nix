{inputs}: {
  config,
  lib,
  ...
}: let
  path = ./ssh_host_ed25519_key.pub;
  key =
    if builtins.pathExists path
    then builtins.readFile path
    else "";
  user = config.systemConstants.username;
in {
  inputs = with inputs.self.modules.bella; [
    helix
    git
    ssh
    localization
    avahi
    systemd-boot
  ];
  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;
}
