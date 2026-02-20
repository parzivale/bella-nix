{self, ...}: {
  flake.modules.nixos.deployable = {
    imports = with self.modules.nixos; [
      openssh
      tailscale
      preservation
    ];
  };
}
