{inputs, ...}: {
  flake.modules.nixos.gtnh = {
    imports = with inputs.gnth-nix.nixosModules; [gtnh "2.8.4"];
    preservation = {
      preserveAt."persistent".directories = ["/var/lib/gtnh"];
    };
  };
}
