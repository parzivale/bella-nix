{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-apple-silicon.nixosModules.default
  ];
  boot = {
    extraModprobeConfig = ''
      options hid_apple iso_layout=0
    '';
    loader.efi.canTouchEfiVariables = false;
  };

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  hardware = {
    # asahi.peripheralFirmwareDirectory = ./firmware;
    asahi.extractPeripheralFirmware = false;
    apple.touchBar = {
      enable = true;
      package = pkgs.tiny-dfr;
    };
  };
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
