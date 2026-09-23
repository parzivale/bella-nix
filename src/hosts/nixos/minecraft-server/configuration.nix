{ inputs }:
{
  config,
  lib,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.constants.username;
in
{
  networking.hostName = "minecraft-server";

  imports = with inputs.self.modules.nixos; [
    nixos
    secrets
    home-manager
    cli
    server
    gtnh
    atm10
    playit
    boot
    network
  ];

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;
}
