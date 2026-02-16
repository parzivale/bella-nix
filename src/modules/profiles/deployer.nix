{self, ...}: {
  flake.modules.nixos.deployer = {
    imports = with self.modules.nixos; [
      nh
      ssh
      git
      tailscale
      preservation
      signed-nix
    ];
  };
}
