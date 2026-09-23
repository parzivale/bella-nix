{
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    state.preserve.directories = [ "/var/lib/bluetooth" ];
  };
}
