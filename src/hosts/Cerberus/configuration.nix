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
    flightcore
    r8126
    modprobed-db
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

  # This box has hard-locked repeatedly (silent freeze, no kernel/journal
  # log survives it, requiring a manual power cycle). These make a future
  # hang actually detectable and recoverable instead of invisible:
  #  - nmi_watchdog + the two panic sysctls turn a soft/hard lockup into an
  #    actual kernel panic instead of a silent unresponsive freeze
  #  - kernel.panic reboots automatically N seconds after any panic
  #  - the systemd watchdog pets /dev/watchdog and forces a hardware reboot
  #    if userspace itself stops responding (catches freezes below the
  #    panic path too, e.g. a fully wedged GPU driver)
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "nmi_watchdog=1"
  ];
  boot.kernel.sysctl = {
    "kernel.hardlockup_panic" = 1;
    "kernel.softlockup_panic" = 1;
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 10;
  };
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "20s";
    RebootWatchdogSec = "30s";
  };

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

}
