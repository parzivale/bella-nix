_:
{
  lib,
  modules,
  ...
}:
{
  # The same machine the nixos Cerberus described, said in what finix has.
  #
  # `enableAllFirmware` and `facter.reportPath` are both here now: facter reads the report
  # and turns it into the initrd's disk modules, amdgpu's own module, the amd_pstate kernel
  # parameter, cpu microcode and redistributable firmware. The one line with no counterpart
  # is `amdgpu.overdrive`, nixos' switch for the sysfs knob lact writes through.
  imports = [ modules.facter ];

  hardware.facter.reportPath = ./facter.json;

  # Beyond what the report implies: every blob rather than only the redistributable ones,
  # which is what the nixos host asked for.
  hardware.enableAllFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
