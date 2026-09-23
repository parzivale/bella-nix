let
  # Both module sets declare `time.timeZone` and `i18n.*`, so the same
  # definition serves either class - published under both rather than as one
  # `generic` module, so each carries its class and the import lists stay
  # uniform.
  localization = {
    time.timeZone = "Europe/Stockholm";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "sv_SE.UTF-8";
        LC_IDENTIFICATION = "sv_SE.UTF-8";
        LC_MEASUREMENT = "sv_SE.UTF-8";
        LC_MONETARY = "sv_SE.UTF-8";
        LC_NAME = "sv_SE.UTF-8";
        LC_NUMERIC = "sv_SE.UTF-8";
        LC_PAPER = "sv_SE.UTF-8";
        LC_TELEPHONE = "sv_SE.UTF-8";
        LC_TIME = "sv_SE.UTF-8";
      };
    };
  };
in
{
  flake.modules.nixos.localization = localization;
  flake.modules.finix.localization = localization;
}
