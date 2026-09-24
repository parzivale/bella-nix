{ inputs, ... }:
{
  flake.modules.nixos.pipewire = {
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };

  flake.modules.finix.pipewire =
    { modules, ... }:
    {
      imports = [
        modules.pipewire
        # finix leaves device management off; this module's rules go nowhere
        # without it. No nixos counterpart - see `udev`.
        inputs.self.modules.finix.udev
      ];

      # One namespace over - finix puts pipewire under `programs` - and only
      # the system half. finix's module lays down packages, udev rules, the
      # ALSA plugin config and the audio rtprio limits; it starts nothing.
      #
      # So there is no `pulse.enable` to set: on finix, pipewire and
      # pipewire-pulse are user services, and this module has no user-session
      # story yet. `pulse.settings` exists for configuring the server once
      # something runs it.
      programs.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
}
