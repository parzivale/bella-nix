{ inputs, ... }:
{
  # Owns nix-minecraft for the whole flake: the upstream module and the overlay
  # that supplies `pkgs.fabricServers` and friends. Both fabric and atm10 need
  # them, and `nixpkgs.overlays` is a list — declaring the overlay in each would
  # apply it twice on a host running both, so it lives here and they import it.
  flake.modules.nixos.nix-minecraft = {
    imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
  };
}
