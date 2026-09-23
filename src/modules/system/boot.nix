{
  # How the machine boots. nixos-only so far: the finix counterpart is limine,
  # which is a different loader rather than a different spelling of this one, so
  # it waits until a finix host actually has to boot.
  flake.modules.nixos.boot = {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 20;
        };
      };
    };
  };
}
