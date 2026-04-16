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
  imports = with inputs.self.modules.nixos; [
    cli
    server
    # networking
    avahi
    # services
    grocy
    synapse
    mas
    pocket-id
    acme
    postgres
    nginx
  ];

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  services.tailscale = {
    extraUpFlags = ["--advertise-exit-node"];
    useRoutingFeatures = "server";
  };

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;
}
