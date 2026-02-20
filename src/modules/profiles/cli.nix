{inputs, ...}: {
  flake.modules.nixos.cli = {
    imports = with inputs.self.modules.nixos; [
      lazygit
      yazi
      git
      nh
      ssh
      helix
      starship
      nushell
    ];
  };
}
