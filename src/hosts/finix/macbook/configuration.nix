{ inputs }:
{
  config,
  lib,
  pkgs,
  modules,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.constants.username;
in
{
  networking.hostName = "macbook";

  imports =
    (with inputs.self.modules.finix; [
      system
      secrets
      home-manager
      cli
      deployer
      deployable
      desktop
      remote-builder
      # hardware
      iwd
      zram
      # power
      upower
      poweralertd
      # system
      wireshark
      use-x86-builders
    ])
    ++ [
      # FEX, below. binfmt_misc registration is a finix module of its own rather than part of
      # the always-loaded set, so it is named here.
      modules.binfmt

      # sinit, for the backend named below. finit is always loaded; this one is not.
      modules.sinit
    ];

  # sinit rather than finit, which is a measurement and not a preference.
  #
  # The same no-initrd boot, same VM, same disk image, same units, with only the backend
  # changed (finix tests/no-initrd-sinit and its finit twin):
  #
  #   sinit:  multi-user at 0.63s, trunk top at 5.81s
  #   finit:  multi-user at 1.94s, trunk top at 7.23s
  #
  # Three times faster to multi-user, which was the opposite of what was expected: finix builds
  # sinit's dependency graph out of shell loops, where finit has one in C. What that says is
  # that finit's cost here is not computing the graph but starting up - reading its
  # configuration, building the graph, and scheduling between units - and sinit does none of it
  # because what finix hands it is a set of self-contained scripts that simply run.
  #
  # sinit itself is 92 lines: it blocks every signal, execs one child, and answers four signals.
  # Everything else - supervision, readiness, ordering, the trunk - is finix's, in shell. There
  # is no notify or s6 readiness and no waitFor.pidfile, which the contract refuses at
  # evaluation rather than downgrading; this machine declares none of them, now that tailscaled
  # names its socket as well as sd_notify.
  #
  # What it gives up against finit: a fixed respawn backoff rather than crash-loop detection,
  # and no start or stop timeout bounds. Services are still supervised and still restarted -
  # speakersafetyd depends on that and it still holds.
  sinit.enable = true;

  # x86_64 Wine, through FEX rather than qemu.
  #
  # The nixos host's comment claimed qemu took priority over this by alphabetical registration
  # order, from `boot.binfmt.emulatedSystems` - but that list was empty and had been for a
  # while, so FEX was the only registration on the machine and the ordering never mattered.
  # Nothing derives qemu registrations here either; a system to emulate would be named the same
  # way this is.
  boot.binfmt.registrations.fex-x86_64 = {
    interpreter = "${pkgs.fex-headless}/bin/FEXInterpreter";
    magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
    mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
  };

  # 24GB, on the persistent subvolume. No `size`: nixos creates a swapfile it is given a size
  # for, and finix mounts what is already there - so the file is made once, out of band, with
  #
  #   btrfs filesystem mkswapfile --size 24g /persistent/swapfile
  swapDevices = [
    {
      device = "/persistent/swapfile";
      priority = 1;
    }
  ];

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;

  # The nixos host emptied `tailscaled-autoconnect`'s `wantedBy`, and this is the same thing
  # said here: community-modules' tailscale module calls its unit `tailscale-up`, and nothing
  # in the graph requires it, so disabling it strands nothing.
  #
  # Which is safe because the join is not what this does. `/var/lib/tailscale` is preserved, so
  # the node stays authenticated across a reboot and `tailscaled` brings the interface up from
  # that state on its own. `tailscale up` re-running every boot - re-asserting the auth key and
  # the tags - is what the unit is for, and a laptop which joined once does not need it.
  #
  # The consequence to know about: a machine which has never joined, or whose state was wiped,
  # will not join by itself. Enable this for that boot.
  providers.services.units.tailscale-up.enable = false;

  # The three daemons which drive hardware qemu does not have. Off in the VM, because each one
  # otherwise exits and is restarted ten times before finit gives up - which spams the console
  # and keeps the machine from reaching `running`.
  #
  # None of them is misconfigured; they are each correct to refuse:
  #
  #   speakersafetyd  matches on the device-tree compatible, `linux,dummy-virt` under qemu, and
  #                   has no speaker profile for it. It ships one per Apple board - j413 and j493
  #                   among them - so the real machine matches. Refusing to drive amps it has no
  #                   protection curve for is the only safe answer.
  #   tiny-dfr        panics on a missing file: there is no /dev/dri at all in the VM, so there
  #                   is no Touch Bar display to open.
  #   greetd          has nothing to start a graphical session on, for the same reason.
  #
  # Which means this says nothing about whether they work on the machine - only that a VM is not
  # where that gets tested.
  virtualisation.vmVariant.providers.services.units = {
    speakersafetyd.enable = false;
    tiny-dfr.enable = false;
    greetd.enable = false;
  };

  # The session's own daemons need nothing said here. They are not system units any more: they
  # belong to a tree a session starts, and a VM with no greetd starts no session, so nothing in
  # that tree runs and there is nothing to disable.

  # `security.polkit.enablePkexecWrapper` has no counterpart: finix's polkit module installs
  # the setuid pkexec wrapper whenever polkit is enabled, so there is nothing to turn on.

  # `loglevel=3` is temporary, for one experiment: the kernel's own chatter buries finit's unit
  # sequence on the console, and a boot which hangs before syslogd leaves the console as the only
  # evidence there is. Quiet it and what survives on screen is which unit finit stopped at.
  # `button.lid_init_state` is gone, and was never doing anything on this machine. It is a
  # parameter of `drivers/acpi/button.c`, and there is no ACPI here: /proc/acpi does not exist,
  # and the lid is `platform:macsmc-input`, a driver which never reads it. The module loads and
  # reports `ACPI: button: Initial lid state set to 'open'` on every boot, governing nothing.
  # Carried over from x86, where it would have meant something.
  boot.kernelParams = [
    "loglevel=3"
  ];

  services.elogind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";

    # Shortened from the 30s default, which exists to swallow exactly the spurious post-resume
    # lid events this machine turns out not to deliver - see below. Kept rather than dropped
    # because it is the stock mechanism for that and costs nothing; three seconds is enough
    # insurance, and thirty would mean closing the lid shortly after a wake did nothing.
    HoldoffTimeoutSec = "3";
  };

  # There was a `providers.resumeAndSuspend` hook here - `swallow-stale-lid-close` - which took
  # a `handle-lid-switch` block inhibitor for three seconds after every resume, against a stale
  # lid-close this machine was said to deliver on wake and be put straight back to sleep by.
  # `LidSwitchIgnoreInhibited = "no"` went with it, and existed only to make elogind honour it.
  #
  # Measured on linux-asahi 7.1.13, with evtest on the lid's own input device across a real
  # lid-triggered cycle - closed, suspended for two and a half minutes, opened:
  #
  #   23:34:03.97  SW_LID value 1      lid closed
  #   23:34:05     PM: suspend entry   (s2idle)
  #   23:36:33     PM: suspend exit
  #   23:36:33.25  SW_LID value 0      lid opened
  #   (nothing)                        twenty seconds later, still watching
  #
  # No stale close, so there is nothing for an inhibitor to swallow. A `loginctl suspend` with
  # the lid untouched is the weaker version of this test and says less: with no lid transition
  # there is nothing for the driver to replay, so only the lid-triggered path answers it.
  #
  # One sample. If this comes back, it comes back as a laptop which re-suspends the moment it is
  # opened, and the hook is in the history.
  #
  # The close-to-suspend decision takes about a second, which is worth knowing separately:
  # closing and reopening faster than that suspends anyway, because the decision is already
  # committed. That is latency, not this.

  home-manager.users.${user} =
    { pkgs, ... }:
    {
      home = {
        stateVersion = "25.11";
        packages = [ pkgs.brightnessctl ];
      };

      programs.niri.settings = {
        input = {
          touchpad.scroll-factor = 0.5;
          keyboard.xkb.layout = "es";
        };
        binds = {
          # The panel, which is brightnessctl's first choice with no `-d` - apple-panel-bl, the
          # only device of class `backlight` that is not the Touch Bar's own. Independent of the
          # bar now that tiny-dfr is not reading it; see `AdaptiveBrightness` on the host.
          "XF86MonBrightnessUp".action.spawn = [
            "brightnessctl"
            "set"
            "5%+"
          ];
          "XF86MonBrightnessDown".action.spawn = [
            "brightnessctl"
            "set"
            "5%-"
          ];

          # `kbd_backlight`, not `apple::kbd_backlight`, which is what this said and which does
          # not exist on this machine:
          #
          #   Device 'apple::kbd_backlight' not found.
          #
          # brightnessctl exits non-zero, niri spawns it and does not report the status, so both
          # keys have been doing nothing at all. The device is a LED rather than a backlight -
          # /sys/class/leds/kbd_backlight, max 255 - and `-d` takes the bare name.
          "XF86KbdBrightnessUp".action.spawn = [
            "brightnessctl"
            "-d"
            "kbd_backlight"
            "set"
            "5%+"
          ];
          "XF86KbdBrightnessDown".action.spawn = [
            "brightnessctl"
            "-d"
            "kbd_backlight"
            "set"
            "5%-"
          ];
        };
      };
    };
}
