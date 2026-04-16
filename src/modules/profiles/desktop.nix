# Scope: complete graphical desktop experience — Wayland compositor, theming,
# audio, notifications, power management, networking, and core GUI apps.
# Use this on any machine with a display.
{self, ...}: {
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      preservation
      stylix
      localization
      # compositor + GUI apps
      niri
      wezterm
      lazygit
      yazi
      zen
      walker
      # desktop hardware/services
      pipewire
      bluetooth
      networkd
      mako
      hibernation
    ];
  };
}
