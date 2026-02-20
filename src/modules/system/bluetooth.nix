{
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    preservation.preserveAt."/persistent".directories = ["/var/lib/bluetooth"];
  };
}
