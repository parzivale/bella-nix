{ inputs }:
{
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
