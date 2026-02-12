{pkgs, ...}: {
  flake.modules.bella.systemd-boot = {
    boot = {
      loader = {
        systemd-boot.enable = true;
      };
    };
  };
}
