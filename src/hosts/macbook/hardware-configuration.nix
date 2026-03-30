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
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [];

  services.xserver.xkb.layout = "es";
  console.keyMap = "es";

  hardware = {
    asahi = {
      peripheralFirmwareDirectory = ./firmware;
    };
    apple.touchBar = {
      enable = true;
      package = pkgs.tiny-dfr;
      settings.MediaLayerDefault = true;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
