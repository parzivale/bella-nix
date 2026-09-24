{ inputs, ... }:
{
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    state.preserve.directories = [ "/var/lib/bluetooth" ];
  };

  flake.modules.finix.bluetooth =
    { modules, ... }:
    {
      imports = [
        modules.bluetooth
        # finix leaves device management off; this module's rules go nowhere
        # without it. No nixos counterpart - see `udev`.
        inputs.self.modules.finix.udev
      ];

      # `powerOnBoot` is nixpkgs' name for bluez's `Policy.AutoEnable`, which
      # finix's module already defaults on.
      services.bluetooth.enable = true;

      state.preserve.directories = [ "/var/lib/bluetooth" ];
    };
}
