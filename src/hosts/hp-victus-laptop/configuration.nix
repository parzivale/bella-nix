{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.systemConstants.username;
in
{
  imports = with inputs.self.modules.nixos; [
    cli
    deployer
    deployable
    desktop
    remote-builder
    # GPU + monitor control
    nvidia
    ddcutil
    # gaming
    discord
    osu
    steam
    sober
    flightcore
    # system
    zram
    use-arm-builders
  ];

  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  swapDevices = [
    {
      device = "/persistent/swapfile";
      size = 24576;
      priority = 1;
    }
  ]; # 24GB

  nix.settings.extra-platforms = [ "i686-linux" ];

  btop.gpu.nvidia = true;

  services.xserver.xkb.layout = "us";

  system.stateVersion = "25.05";
  home-manager.users.${user} = {
    home.stateVersion = "25.11";
    # programs.niri.settings.xwayland-satellite.enable = false;

    # The only active output (HDMI-A-1) hangs off the NVIDIA card, but the AMD
    # iGPU is boot_vga=1 so niri picks it as the primary render node by default.
    # That puts a cross-GPU copy on every composited frame. Pin rendering to the
    # card that owns the display. Uses the PCI path since renderD* numbering
    # isn't guaranteed stable across boots.
    programs.niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-0000:01:00.0-render";
  };
}
