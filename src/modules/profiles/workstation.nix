# Scope: personal workstation apps present on all of your machines.
# Use alongside cli + deployer + desktop for a full workstation setup.
{self, ...}: {
  flake.modules.nixos.workstation = {
    imports = with self.modules.nixos; [
      _1password
      claude
      spotify-player
      prismlauncher
      remote-builder
    ];
  };
}
