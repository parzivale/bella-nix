{self, ...}: {
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      preservation
      stylix
      niri
    ];
  };
}
