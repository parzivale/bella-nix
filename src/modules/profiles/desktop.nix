# Scope: complete graphical desktop experience — Wayland compositor, theming,
# audio, notifications, power management, networking, and core GUI apps.
# Use this on any machine with a display.
{self, ...}: {
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      localization
      metrics
      stylix
      # CLI aps
      iamb
      # compositor + GUI apps
      niri
      wezterm
      lazygit
      yazi
      zen
      walker
      _1password
      claude
      spotify-player
      prismlauncher
      # desktop hardware/services
      pipewire
      bluetooth
      networkd
      mako
      hibernation
      avahi
      systemd-boot
    ];
  };
}
