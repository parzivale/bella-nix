_:
let
  # Kept in the menu, and the same number either way: both loaders are keeping
  # generations off a full ESP.
  generations = 20;
in
{
  # How the machine boots - and the one module where the two classes are not two
  # spellings of one thing. nixos boots through systemd-boot; finix's only
  # `providers.bootloader` implementation is limine, a different loader with its
  # own configuration and its own install program.
  #
  # What is the same is the shape of the decision: EFI, twenty generations kept,
  # and no writing to EFI variables - so on both, the loader goes in the ESP and
  # the firmware is left to find it.
  flake.modules.nixos.boot = {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = generations;
    };
  };

  flake.modules.finix.boot =
    {
      lib,
      modules,
      ...
    }:
    {
      imports = [
        modules.limine
        # limine's installer is handed `services.nix-daemon.package` to run nix
        # commands with, so the option has to exist. Importing the module is not
        # enabling the daemon; `nix` does that.
        modules.nix-daemon
      ];

      # What limine reads to decide between registering a boot entry and installing
      # to the removable path. True, so it registers one with efibootmgr - which is
      # what systemd-boot does on the nixos side, and what makes the firmware find
      # the loader rather than leaving it to boot order.
      #
      # A default rather than a setting, because it is a fact about the machine and
      # not about the loader: a host whose firmware cannot be written to says false
      # and gets the removable install. An Apple Silicon machine is that host -
      # U-Boot looks for the removable path and nothing else - though it has larger
      # problems than this one, `nixos-apple-silicon` being a nixos module tree that
      # writes grub, systemd-boot and limine option paths finix does not have.
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

      programs.limine = {
        enable = true;

        maxGenerations = generations;

        # `efiSupport` is not set: it defaults from `hostPlatform.isEfi`, which is
        # true here. Nor is `efiInstallAsRemovable`, which follows the option above.
      };
    };
}
