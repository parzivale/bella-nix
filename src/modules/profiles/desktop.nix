{self, ...}: {
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      localization
      alloy
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
      swaync
      swayidle
      avahi
      systemd-boot
    ];
  };
}
