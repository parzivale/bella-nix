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

  imports = with inputs.self.modules.finix; [
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

  # What pid 1 is. The nixos Cerberus has no equivalent line because the answer
  # there is never in question.
  finit.enable = true;

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

  # `size` has no counterpart: nixos creates the swapfile when told how big, and
  # finix only mounts one that is already there. Which it is - /persistent
  # survives the tmpfs root, so the 40G file the nixos Cerberus made is still on
  # the disk this boots from.
  #
  # The priority is what matters and does carry over: zram takes 5 by default, so
  # 1 here keeps the compressed tier ahead of the disk.
  swapDevices = [
    {
      device = "/persistent/swapfile";
      priority = 1;
    }
  ];

  # `system.stateVersion` has no counterpart: finix has no such option, there
  # being no decade of nixos option renames behind it to opt out of. The
  # home-manager one stays, being home-manager's own.
  home-manager.users.${user}.home.stateVersion = "25.11";

  btop.gpu.amd = true;

  # gaming rig: don't let powertop's auto-tune (ASPM/USB/SATA power saving) fight
  # for latency. `powerManagement.powertop` over there; finix keeps it under
  # `services` with tlp and thermald.
  services.powertop.enable = lib.mkForce false;

  age.rekey.hostPubkey = lib.mkIf (key != "") key;
}
