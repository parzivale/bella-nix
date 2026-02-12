{self, ...}: {
  flakes.modules.bella.desktop = {
    imports = with self.modules.bella; [
      preservation
      stylix
      niri
    ];
  };
}
