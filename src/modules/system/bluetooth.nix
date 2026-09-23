{
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    state.preserve.directories = [ "/var/lib/bluetooth" ];
  };

  flake.modules.finix.bluetooth =
    { modules, ... }:
    {
      imports = [ modules.bluetooth ];

      # `powerOnBoot` is nixpkgs' name for bluez's `Policy.AutoEnable`, which
      # finix's module already defaults on.
      services.bluetooth.enable = true;

      state.preserve.directories = [ "/var/lib/bluetooth" ];
    };
}
