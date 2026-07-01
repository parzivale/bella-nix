{ self, ... }:
{
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      localization
      stylix
      # CLI aps
      iamb
      # compositor + GUI apps
      niri
      wezterm
      lazygit
      yazi
      zen
      fuzzel
      _1password
      claude
      spotify-player
      prismlauncher
      blender
      # desktop hardware/services
      xdg-desktop-portal-termfilepickers
      keyring
      pipewire
      bluetooth
      networkd
      mako
      swayidle
      avahi
      printing
      systemd-boot
      kernel
      powertop
    ];
  };
}
