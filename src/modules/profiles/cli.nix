{inputs, ...}: {
  flake.modules.nixos.cli = {
    imports = with inputs.self.modules.nixos; [
      lazygit
      git
      nh
      ssh
      helix
    ];
  };
}
