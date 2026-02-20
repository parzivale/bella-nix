{self, ...}: {
  flake.modules.nixos.server = {
    imports = with self.modules.nixos; [
      stylix
      preservation
    ];
  };
}
