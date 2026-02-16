{inputs, ...}: {
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [
      user
      home-manager
      nix
      systemd-boot
      systemd-resolved
      systemConstants
    ];
  };
}
