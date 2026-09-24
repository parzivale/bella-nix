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
  user = config.constants.username;
in
{
  networking.hostName = "Cerberus";

  imports = with inputs.self.modules.nixos; [
    system
    secrets
    home-manager
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
    flightcore
    r8126
    modprobed-db
    # linuxPackages_cachyos below
    chaotic
  ];

  # chaotic-nyx's _processor_opt only knows NATIVE/ZEN4/GENERIC_Vn (mirrors
  # arch/x86/Kconfig.cpu, which has no MZEN5 choice yet). But -march is just
  # a KBUILD_CFLAGS entry appended after the Kconfig-driven one in
  # arch/x86/Makefile, and KCFLAGS is appended last of all in the top-level
  # Makefile — so it wins regardless of which CPU choice Kconfig picked, and
  # regardless of which host actually compiles it.
  boot.kernelPackages = pkgs.linuxPackages_cachyos.extend (
    _final: prev: {
      kernel = prev.kernel.overrideAttrs (old: {
        buildFlags = (old.buildFlags or [ ]) ++ [ "KCFLAGS=-march=znver5 -mtune=znver5" ];
      });
    }
  );

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

  # Not powertop's to suspend either: the same latency argument as the line above,
  # aimed at the devices rather than at the tuner.
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

}
