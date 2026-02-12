{self, ...}: {
  flakes.modules.bella.cli = {
    imports = with self.modules.bella; [
      lazygit
      git
      nh
      ssh
      helix
    ];
  };
}
