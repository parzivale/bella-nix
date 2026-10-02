{ inputs }:
{
  config,
  lib,
  modules,
  ...
}:
{
  imports = [
    # The asahi module tree, which carries no class stamp so finix can import it, plus the
    # compatibility layer which declares the option paths it writes to and forwards the ones
    # with somewhere to go. That layer is also what turns asahi's
    # `systemd.packages = [ speakersafetyd ]` into `services.speakersafetyd.enable` - the
    # speaker protection is not optional on this hardware, so it asserts rather than dropping
    # the unit quietly.
    inputs.nixos-apple-silicon.nixosModules.default
    inputs.community-modules.nixosModules.apple-silicon

    # The hardware report: the initrd's disk and keyboard modules, redistributable firmware,
    # and the graphics card's own module, all read out of facter.json.
    modules.facter

    # The Touch Bar.
    modules.tiny-dfr
  ];

  # speakersafetyd in the session, beside the sound server it was racing.
  #
  # The ordering was said two ways before this and neither worked. First as a named edge -
  # wireplumber waiting for the protection - and then structurally, by putting speakersafetyd in
  # `basic` so that `multi-user`, and therefore every session, was behind it. The second is
  # sound reasoning and it did not help, because a unit's readiness defaults to `fork`: finit
  # asserts it the instant the process exists, so `basic` cleared while the daemon was still
  # working out what it was protecting, and the session came up underneath it anyway.
  #
  # It also had the wrong failure in mind. The comment here described `snd_ctl_elem_lock`
  # contention, which is what the upstream unit is written against. What actually happens on
  # this machine, finally readable once the daemon's stderr reached the log:
  #
  #   22:23:00  speakersafetyd[2059]: PCM rate: 8000..192000
  #   22:23:02  pipewire starts
  #   22:23:02  speakersafetyd[2059]: thread 'main' panicked at src/main.rs:298:17:
  #   22:23:02  speakersafetyd[2059]: Invalid sample rate
  #
  # Not a lock at all. The sound server opens the card and changes its rate while the daemon is
  # reading it, and the daemon panics. Two seconds later finit restarts it, the card has
  # settled, and it comes up - which is why this looked like nothing for as long as nobody could
  # read what it said.
  #
  # So it wants to start *after* pipewire, and that edge has nowhere to live in the trunk: a
  # system unit cannot name a user unit, which is the same refusal that stopped wireplumber
  # naming speakersafetyd. Beside pipewire it is one line.
  #
  # What that gives up is less than it looks. CAP_SYS_NICE goes, and `sched_setattr` failing is
  # a `warn!` - more scheduling jitter, no less protection. The ALSA control device comes
  # through the session's device ACLs, which is how pipewire reaches it. The flag file at
  # /run/speakersafetyd goes too, and that one fails in the safe direction: no flag means "warm
  # boot", and warm boot is the conservative branch - the coils are assumed to be at the
  # thermal limit and gain is held down until the model cools them, where a cold boot assumes
  # they are cold and allows full output immediately. The speakers start quiet after a cold boot
  # and come up over the coil's time constant.
  #
  # And the scope: protection exists while a session does. That is safe here because the driver
  # is fail-safe - `snd-soc-macaudio` keeps the speakers limited until this daemon unlocks them,
  # which is the `Speaker volumes unlocked` line in the log - so no session is quiet speakers
  # rather than unprotected ones.
  services.speakersafetyd.session = config.constants.username;

  # ...and in the group which gates its wrapper, because the capability that wrapper grants is
  # not optional.
  #
  # The first version of this ran the bare binary on the reasoning that CAP_SYS_NICE is wanted
  # rather than needed - `sched_setattr` failing is a `warn!`, so it starts and protects and
  # looks fine. It does, until the machine is busy. `Speaker Volume Unlock` is a watchdog the
  # driver expects on a deadline, a loop without realtime scheduling misses it, and the driver
  # locks the speakers itself:
  #
  #   00:40:16 kernel: snd-soc-macaudio sound: Speaker volumes locked: Lock timeout
  #   00:40:19 kernel: snd-soc-macaudio sound: Speaker volumes unlocked
  #   00:40:19 kernel: snd-soc-macaudio sound: Speaker volumes locked: Lock timeout
  #
  # four times in seven seconds, each unlock a restart after a panic, until dinit's restart limit
  # stopped trying and the speakers stayed silent. Audio simply stopped, two hours into a boot,
  # with nothing in any system log to say why - the daemon's output goes to its supervisor's
  # buffer now, not to syslog.
  #
  # What the group grants is one wrapper, which execs one binary, with one capability, as the
  # user who ran it - there is no setuid bit on it. This account is in `wheel` and can become
  # root with its own password, so it is not a boundary that was holding anything here. On a
  # machine with more than one human it would be, which is why the module leaves it to the host.
  users.users.${config.constants.username}.extraGroups = [ "speakersafetyd" ];

  # uinput, which the Touch Bar daemon cannot work without.
  #
  # tiny-dfr draws the bar and emits the function keys pressed on it, and it emits them by
  # creating a virtual input device - which means opening /dev/uinput. CONFIG_INPUT_UINPUT is a
  # module in this kernel and nothing loaded it, so the device node did not exist and the open
  # failed:
  #
  #   panicked at src/main.rs:791:91:
  #   Err value: Os { code: 2, kind: NotFound, message: "No such file or directory" }
  #
  # which accounts for all of it at once: no keys, because there was no device to send them
  # from; nothing drawn, because the panic comes before the first frame; and a backlight sitting
  # at zero, because nothing was there to raise it. It was diagnosed as a brightness problem
  # twice and as a missing font once, from the outside, because the panic itself went nowhere
  # until unit output reached the log.
  #
  # `hardware.uinput` is finix's own module and was simply never enabled - the same shape as the
  # fontconfig, dconf and privileges gaps: the nixos half turns it on, the finix half leaves a
  # default meaning "absent", and nothing says so.
  hardware.uinput.enable = true;

  nixpkgs.overlays = [ inputs.nixos-apple-silicon.overlays.default ];

  hardware.facter.reportPath = ./facter.json;

  hardware.asahi = {
    # Explicit rather than inferred: it defaults on for an Asahi machine today, and asahi warns
    # that it intends to stop doing so.
    enable = true;

    peripheralFirmwareDirectory = ./firmware;
  };

  # nixos spells this `boot.extraModprobeConfig`.
  programs.modprobe.extraConfig = ''
    options hid_apple
  '';
  # Stage 1, still - and the reason is preservation rather than anything about the boot itself.
  #
  # The direct path works: tests/no-initrd-tmpfs boots this disk layout in a VM, the kernel takes
  # the btrfs above the store's subvolume and resolves the bootspec's own `init=` against it, and
  # finix-init pivots to the declared tmpfs. What it cannot do is preserve state, because
  # preservation has no moment to run in.
  #
  # With a stage 1 the order is mount, preserve, switch_root, activate: the persisted state is in
  # place before anything has written to the root. Without one the module moves its work into
  # stage 2 - `mkIf (!config.boot.initrd.enable)` in community-modules' preservation - and the
  # order inverts to mount, activate, finit, mount-filesystems, preserve. Activation then creates
  # /etc, /var/lib and the home directories which preservation bind-mounts over a moment later,
  # so what it wrote is hidden rather than kept. The same shape as the /run/current-system
  # problem modules/boot/root.nix documents, and for the same reason: something ran before the
  # thing that was supposed to make its destination real.
  #
  # It also does not boot, which is how this was found. finit's sysinit barrier gains
  # `task/preservation-started/success`, the task never completes, and the machine stops there -
  # before syslogd, so nothing is logged, on the machine or anywhere else. Three generations
  # died in that silence:
  #
  #   [    4.055195] finit[1]: Starting udev-settle-started[1473]
  #   [   14.047552] apple-pmgr-pwrstate ...: sync_state() pending due to 269080000.avd
  #
  # and then nothing, for ever.
  #
  # So the direct path waits on preservation learning to run inside finix-init, which is where
  # stage 1's moment went. Flipping this back is all that is needed to try again.
  boot.initrd.enable = false;

  # Apple's NVMe, built in rather than modular - only when nothing else can load it.
  #
  # The reasoning is in the patch itself, because it is about when a value can be set rather
  # than what it should be. The short of it: nixpkgs seeds a kernel config with `make defconfig`
  # and then answers questions from its own list, kconfig asks about drivers/nvme before
  # drivers/soc, and so NVMe is decided while APPLE_SART is still whatever the seed said. A
  # tristate cannot be built in over a modular dependency, so the answer is refused, re-asked
  # and the build dies - and the seed is the only place early enough to prevent it.
  #
  # Conditional, because it buys nothing with a stage 1: an initrd carries nvme_apple as a module
  # and loads it before mounting anything, which is what it is for. Kept rather than deleted
  # because it is correct and was not easy to arrive at - and because this comes straight back
  # the moment the line above is false.
  # The one storage driver this machine has, named rather than taken from the default.
  #
  # `boot.kernel.builtinDrivers` otherwise defaults to every driver finix knows, on the
  # reasoning that a machine without an initrd is having a kernel built for it anyway and
  # cannot reliably say which controller its disk is on. This one can: the root is
  # /dev/nvme0n1p5, which is the ANS2 NVMe, and there is nothing else to boot from.
  #
  # It also has to be named, because nvme_apple is excluded from that default - it cannot be
  # built in by answering the configuration generator, only by seeding the defconfig, which is
  # the patch below. A driver which needs a machine-specific patch is not one to put in every
  # machine's kernel automatically, and when it was the no-initrd tests in finix all stopped
  # building: they use the stock kernel and have no reason to patch its defconfig.
  #
  # The rest of the default - ahci, mmc_block, generic nvme, sd_mod, usb_storage, virtio_blk -
  # is hardware this does not have, so dropping it costs nothing and takes about 3 MB off the
  # image along with the initcalls that go with it.
  boot.kernel.builtinDrivers = [ "nvme_apple" ];

  boot.kernelPatches = lib.optionals (!config.boot.initrd.enable) [
    {
      name = "apple-nvme-builtin";
      patch = ./apple-nvme-builtin.patch;
    }
  ];

  # No boot entry is written: limine installs to the removable path, which is what U-Boot's EFI
  # implementation finds on these machines - the same arrangement the nixos host had, where
  # bootctl was always passed --no-variables.
  boot.loader.efi.canTouchEfiVariables = false;

  hardware.console.keyMap = "es";

  # tiny-dfr. The settings are the nixos host's, verbatim: the media layer by default, and the
  # twelve keys it puts there.
  #
  # `Restart = "on-failure"` has no counterpart and needs none. The shipped unit says
  # `Restart=always` and the nixos host narrowed it; here a `type.service` unit is restarted
  # whichever way it exits, which is the behaviour the package asked for to begin with.
  services.tiny-dfr = {
    enable = true;

    settings = {
      MediaLayerDefault = true;

      # The Touch Bar tracks the panel's brightness rather than sitting at a fixed level:
      # `update_backlight` puts apple-panel-bl's brightness through a square-root curve scaled
      # by `ActiveBrightness`, so dimming the screen dims the bar with it.
      #
      # On by default, said here because it is a choice.
      AdaptiveBrightness = true;

      MediaLayerKeys = [
        {
          Icon = "brightness_low";
          Action = "BrightnessDown";
        }
        {
          Icon = "brightness_high";
          Action = "BrightnessUp";
        }
        {
          Icon = "mic_off";
          Action = "MicMute";
        }
        {
          Icon = "screenshot";
          Action = "Sysrq";
        }
        {
          Icon = "backlight_low";
          Action = "IllumDown";
        }
        {
          Icon = "backlight_high";
          Action = "IllumUp";
        }
        {
          Icon = "fast_rewind";
          Action = "PreviousSong";
        }
        {
          Icon = "play_pause";
          Action = "PlayPause";
        }
        {
          Icon = "fast_forward";
          Action = "NextSong";
        }
        {
          Icon = "volume_off";
          Action = "Mute";
        }
        {
          Icon = "volume_down";
          Action = "VolumeDown";
        }
        {
          Icon = "volume_up";
          Action = "VolumeUp";
        }
      ];
    };
  };

  # The icon for the Sysrq key above: tiny-dfr looks in /etc/tiny-dfr before its own share
  # directory, and `screenshot` is not one of the icons it ships.
  environment.etc."tiny-dfr/screenshot.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" height="48" viewBox="0 -960 960 960" width="48"><path fill="white" d="M80-560v-240q0-33 23.5-56.5T160-880h240v80H160v240H80ZM520-880h240q33 0 56.5 23.5T840-800v240h-80v-240H520v-80ZM80-400h80v240h240v80H160q-33 0-56.5-23.5T80-160v-240Zm680 0v240H520v80h240q33 0 56.5-23.5T840-160v-240h-80Z"/></svg>
  '';

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
