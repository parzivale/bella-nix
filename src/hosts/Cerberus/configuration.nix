{ inputs }:
{
  config,
  lib,
  pkgs,
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
    deployer
    deployable
    desktop
    cli
    steam
    mangohud
    iwd
    obs
    lact
  ];

  boot.kernelPackages = pkgs.linuxPackages_cachyos;

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

  # gaming rig: don't let powertop's auto-tune (ASPM/USB/SATA power saving) fight for latency
  powerManagement.powertop.enable = lib.mkForce false;
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

}
