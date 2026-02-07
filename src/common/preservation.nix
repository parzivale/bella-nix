{lib, ...}: {
  # systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];

  # systemd.services.systemd-machine-id-commit = {
  #   unitConfig.ConditionPathIsMountPoint = [
  #     ""
  #     "/persistant/etc/machine-id"
  #   ];
  #   serviceConfig.ExecStart = [
  #     ""
  #     "systemd-machine-id-setup --commit --root /persistant"
  #   ];
  # };

  preservation = {
    # enable = lib.mkDefault true;
    preserveAt."/persistant" = {
      directories = [
        "/etc/secureboot"
        "/var/lib/bluetooth"
        "/var/lib/fprint"
        "/var/lib/fwupd"
        "/var/lib/libvirt"
        "/var/lib/power-profiles-daemon"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/rfkill"
        "/var/lib/systemd/timers"
        "/var/log"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
      ];
    };
  };
}
