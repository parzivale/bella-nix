{self, ...}: {
  flakes.modules.bella.deployable = {
    imports = with self.modules.bella; [
      openssh
      tailscale
    ];
  };
}
