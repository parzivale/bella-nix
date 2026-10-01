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

  # wireplumber waiting for the speaker protection used to be said here, by name.
  #
  # The race it fixed is real - both start in the same second, both want the card's control
  # elements, speakersafetyd locks the ones it protects with `snd_ctl_elem_lock`, and when
  # wireplumber takes them first speakersafetyd panics on the first speaker it tries to claim:
  #
  #   Could not lock elem Left Front VSENSE Switch.
  #   ALSA function 'snd_ctl_elem_lock' failed with error 'Device or resource busy (16)'
  #
  # finit restarted it two seconds later and the second attempt won, so it healed itself and
  # looked like nothing - while the amps were unprotected for two seconds of every boot.
  #
  # It is said in the trunk now instead: speakersafetyd attaches to `basic`, so `multi-user` is
  # not reached until it is up, and every session - and so every user tree, wireplumber included -
  # is behind that. Which it has to be, because wireplumber is a user unit now and a user's
  # supervisor cannot see a system unit at all; the contract refuses the edge rather than letting
  # it wait for ever. The ordering is also no longer this host's to remember, and Cerberus, which
  # has wireplumber and no speakersafetyd, needs nothing said either way.

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
  boot.initrd.enable = true;

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
