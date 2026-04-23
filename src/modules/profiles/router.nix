{self, ...}: {
  flake.modules.nixos.router = {
    imports = with self.modules.nixos; [
      nginx
      acme
    ];
  };
}
