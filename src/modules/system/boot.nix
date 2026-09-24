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
