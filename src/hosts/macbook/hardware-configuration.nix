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

  networking.useNetworkd = true;
  networking.dhcpcd.enable = false;
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [];

  services.xserver.xkb.layout = "es";
  console.keyMap = "es";

  hardware = {
    asahi = {
      peripheralFirmwareDirectory = ./firmware;
    };
    # asahi.extractPeripheralFirmware = false;
    apple.touchBar = {
      enable = true;
      package = pkgs.tiny-dfr;
      settings.MediaLayerDefault = true;
    };
  };

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Apple MTP Touchpad]
    MatchBus=usb
    MatchVendor=0x05AC
    MatchProduct=0x0354
    AttrPalmSizeThreshold=1600
  '';

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
