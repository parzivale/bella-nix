{ self, ... }:
{
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      localization
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
      network
      mako
      swayidle
      avahi
      printing
      boot
      kernel
      powertop
    ];
  };
}
