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

  # wireplumber waits for the speaker protection.
  #
  # Both start in the same second, and both want the card's control elements. speakersafetyd
  # locks the ones it protects - `snd_ctl_elem_lock` on each VSENSE and ISENSE switch - and
  # wireplumber enumerates the card and takes them first often enough to matter. When it wins,
  # speakersafetyd panics on the first speaker it tries to claim:
  #
  #   Could not lock elem Left Front VSENSE Switch.
  #   ALSA function 'snd_ctl_elem_lock' failed with error 'Device or resource busy (16)'
  #
  # finit restarts it two seconds later and the second attempt wins, so this healed itself and
  # looked like nothing - but the amps are unprotected for those two seconds of every boot, and
  # a race lost ten times running is a boot with no protection at all. The ordering that fixes
  # it is also the honest one: these controls are meant to be locked before anything else on the
  # system touches the card.
  #
  # Declared on the host rather than beside either service, because Cerberus has wireplumber and
  # no speakersafetyd, and a unit required by name that does not exist is a branch of the graph
  # that waits for ever.
  providers.services.units.wireplumber.requires = [ "speakersafetyd" ];

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
