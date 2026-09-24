_: {
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
      configurationLimit = 20;
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

        # `configurationLimit` over there. Both mean "how many generations stay in
        # the menu", and both are about the ESP not filling up.
        maxGenerations = 20;

        # `efiSupport` is not set: it defaults from `hostPlatform.isEfi`, which is
        # true for both machines. `efiInstallAsRemovable` follows
        # `boot.loader.efi.canTouchEfiVariables`, false on both, so limine installs
        # to the fallback path the firmware looks at when no entry names it -
        # which is also how the macbook's chain finds a loader, U-Boot looking for
        # exactly that.
      };
    };
}
