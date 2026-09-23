{ inputs, ... }:
{
  # The NixOS implementation of `state.preserve`: everything modules have
  # contributed lands under /persistent, on top of the baseline below. Those
  # baseline entries stay here rather than in `state.preserve` because they are
  # systemd's own state — nothing another class would want to inherit.
  flake.modules.nixos.preservation =
    { config, lib, ... }:
    {
      imports = [
        inputs.preservation.nixosModules.preservation
      ];
      boot.initrd.systemd.enable = true;

      systemd.services.systemd-machine-id-commit = {
        unitConfig.ConditionPathIsMountPoint = [
          ""
          "/persistent/etc/machine-id"
        ];
        serviceConfig.ExecStart = [
          ""
          "systemd-machine-id-setup --commit --root /persistent"
        ];
      };

      preservation = {
        enable = true;
        preserveAt."/persistent" = {
          directories = [
            "/etc/secureboot"
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
          ]
          ++ config.state.preserve.directories;
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
            {
              file = "/etc/ssh/ssh_host_ed25519_key";
              how = "symlink";
              configureParent = true;
              inInitrd = true;
            }
            {
              file = "/etc/ssh/ssh_host_ed25519_key.pub";
              how = "symlink";
              configureParent = true;
              inInitrd = true;
            }
            {
              file = "/var/lib/systemd/random-seed";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
          ]
          ++ config.state.preserve.files;

          users = lib.mapAttrs (_: user: {
            inherit (user) directories files;
          }) config.state.preserve.users;
        };
      };
    };
}
