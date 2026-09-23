{ self, ... }:
{
  flake.modules.nixos.desktop = {
    imports = [
      # class-neutral, so it lives under `generic` rather than `nixos`
      self.modules.generic.localization
    ]
    ++ (with self.modules.nixos; [
      stylix
      # CLI aps
      iamb
      direnv
      github
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
    ]);
  };
}
