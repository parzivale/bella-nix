{self, ...}: {
  flakes.modules.bella.deployer = {
    imports = with self.modules.bella; [
      nh
      ssh
      git
      tailscale
    ];
  };
}
