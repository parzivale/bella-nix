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

              # preservation defaults a file to 0644, and its tmpfiles `f` rule applies that to
              # the file whether or not it created it - so the default does not merely miss a
              # private key's mode, it overwrites a correct one on every boot. sshd then refuses
              # to load it ("Permissions 0644 ... are too open") and exits with no host keys at
              # all, which is how this was found.
              mode = "0600";
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

              # 0600 for the same reason as the host key above: systemd creates the seed that
              # way and a readable one is worth less than no seed at all.
              mode = "0600";
            }
          ]
          ++ config.state.preserve.files;

          users = lib.mapAttrs (_: user: {
            inherit (user) directories files;
          }) config.state.preserve.users;
        };
      };
    };

  # The finix implementation of the same contract. `state.preserve` is
  # class-neutral by construction, so what a module asked to keep is already
  # here; only the baseline differs, because the baseline is whatever the init
  # and its services leave lying around.
  flake.modules.finix.preservation =
    { config, lib, ... }:
    {
      imports = [ inputs.community-modules.nixosModules.preservation ];

      preservation = {
        enable = true;
        preserveAt."/persistent" = {
          directories = [
            "/var/log"
          ]
          ++ config.state.preserve.directories;

          files = [
            # The machine's identity. NixOS keeps it at /etc/machine-id; here
            # dbus generates it with `dbus-uuidgen --ensure` and /etc/machine-id
            # is a tmpfiles symlink to this, recreated every boot - so this is
            # the file worth keeping, and preserving the symlink would keep
            # nothing.
            "/var/lib/dbus/machine-id"
          ]
          ++ config.state.preserve.files;

          users = lib.mapAttrs (_: user: {
            inherit (user) directories files;
          }) config.state.preserve.users;
        };
      };

      # Nothing corresponds to the nixos side's initrd systemd or its
      # machine-id-commit override: both are systemd putting its own state in
      # order, and the ssh host key is preserved by the openssh module, which
      # is where the path it uses is decided.
    };
}
