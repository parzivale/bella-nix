{self, ...}: {
  flakes.modules.bella.server = {
    imports = with self.modules.bella; [
      stylix
      preservation
    ];
  };
}
