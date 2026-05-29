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
    binfmt.emulatedSystems = ["x86_64-linux"];
    # kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 31;
  };

  # networking.useNetworkd = true;
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
      settings = {
        MediaLayerDefault = true;
        MediaLayerKeys = [
          {
            Icon = "brightness_low";
            Action = "BrightnessDown";
          }
          {
            Icon = "brightness_high";
            Action = "BrightnessUp";
          }
          {
            Icon = "mic_off";
            Action = "MicMute";
          }
          {
            Icon = "screenshot";
            Action = "Sysrq";
          }
          {
            Icon = "backlight_low";
            Action = "IllumDown";
          }
          {
            Icon = "backlight_high";
            Action = "IllumUp";
          }
          {
            Icon = "fast_rewind";
            Action = "PreviousSong";
          }
          {
            Icon = "play_pause";
            Action = "PlayPause";
          }
          {
            Icon = "fast_forward";
            Action = "NextSong";
          }
          {
            Icon = "volume_off";
            Action = "Mute";
          }
          {
            Icon = "volume_down";
            Action = "VolumeDown";
          }
          {
            Icon = "volume_up";
            Action = "VolumeUp";
          }
        ];
      };
    };
  };

  systemd.services.tiny-dfr.serviceConfig.Restart = "on-failure";

  environment.etc."tiny-dfr/screenshot.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" height="48" viewBox="0 -960 960 960" width="48"><path fill="white" d="M80-560v-240q0-33 23.5-56.5T160-880h240v80H160v240H80ZM520-880h240q33 0 56.5 23.5T840-800v240h-80v-240H520v-80ZM80-400h80v240h240v80H160q-33 0-56.5-23.5T80-160v-240Zm680 0v240H520v80h240q33 0 56.5-23.5T840-160v-240h-80Z"/></svg>
  '';

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
