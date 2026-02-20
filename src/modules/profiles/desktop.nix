{self, ...}: {
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      preservation
      stylix
      niri
      wezterm
      lazygit
      localization
      yazi
      zen
      walker
    ];
  };
}
