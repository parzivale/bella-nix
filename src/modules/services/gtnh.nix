{inputs, ...}: {
  flake.modules.nixos.gtnh = {
    imports = with inputs.gtnh-nix; [nixosModules.gtnh nixosModules."2.8.4"];
    preservation = {
      preserveAt."/persistent".directories = ["/var/lib/gtnh"];
    };
  };
}
