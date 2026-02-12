{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];

  boot.loader.efi.canTouchEfiVariables = false;
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  boot.kernelParams = ["boot=live"];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
