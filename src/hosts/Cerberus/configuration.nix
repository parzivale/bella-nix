{ inputs }:
{
  config,
  lib,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.systemConstants.username;
in
{
  imports = with inputs.self.modules.nixos; [
    zram
    use-arm-builders
    deployable
    desktop
    cli
    steam
  ];

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 40960;
      priority = 1;
    }
  ];

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  btop.gpu.amd = true;

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

}
