_:
let
  # Kept in the menu, and the same number either way.
  #
  # Six, which is an arithmetic answer rather than a taste one. macbook's ESP is 476M and each
  # generation puts a kernel and an initrd on it - about 38M for an asahi kernel and its
  # compressed initramfs - so twenty of them is 760M into a partition that cannot hold it. What
  # that produced was not an error: the limine installer copies first and prunes last, so on a
  # full ESP the copy fails before anything is freed, and `switch-to-configuration boot` reported
  # success while the menu went on offering whichever generations still had files. Three switches
  # landed and the machine booted the same stale generation every time.
  #
  # Six leaves headroom at roughly half the partition. The number this replaced was deliberate -
  # "EFI, twenty generations kept" was a considered choice shared with the systemd-boot side - and
  # it was simply never checked against the size of the disk it was writing to.
  generations = 6;
in
{
  # How the machine boots - and the one module where the two classes are not two
  # spellings of one thing. nixos boots through systemd-boot; finix's only
  # `providers.bootloader` implementation is limine, a different loader with its
  # own configuration and its own install program.
  #
  # What is the same is the shape of the decision: EFI, six generations kept,
  # and no writing to EFI variables - so on both, the loader goes in the ESP and
  # the firmware is left to find it.
  flake.modules.nixos.boot = {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = generations;
    };
  };

  flake.modules.finix.boot =
    { modules, ... }:
    {
      imports = [
        modules.limine
        # limine's installer is handed `services.nix-daemon.package` to run nix
        # commands with, so the option has to exist. Importing the module is not
        # enabling the daemon; `nix` does that.
        modules.nix-daemon
      ];

      programs.limine = {
        enable = true;

        maxGenerations = generations;

        # Neither `efiSupport` nor `efiInstallAsRemovable` is set, and the second is
        # the interesting one: it follows `boot.loader.efi.canTouchEfiVariables`,
        # false here as it is on nixos, so limine installs to the removable path.
        #
        # Which is the right path, not a fallback. nixos has been passing
        # `--no-variables` to bootctl on these machines for as long as they have
        # existed, so no boot entry was ever written and the removable loader is
        # what the firmware finds. limine lands in the same place, meaning either
        # class can be deployed to the machine and it boots - and nothing writes
        # NVRAM, which is the one bootloader operation with a history of bricking
        # boards.
      };
    };
}
