_:
{ lib, ... }:
{
  # The same machine the nixos Cerberus describes, said in what finix has.
  #
  # Three of that host's four hardware lines have no counterpart here.
  # `enableAllFirmware` is nixos bundling every redistributable blob;
  # `amdgpu.overdrive` is its switch for the sysfs knob lact uses; and
  # `facter.reportPath` is nixos-facter, a nixos module which reads a hardware
  # report and turns it into kernel modules and firmware. What replaces all three
  # is saying the few things they were being asked to infer.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
