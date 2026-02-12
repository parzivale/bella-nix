{self, ...}: {
  flake.modules.bella.base = {
    imports = with self.modules.bella; [user home-manager nix];
  };
}
