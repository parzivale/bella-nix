{inputs, ...}: {
  flake.modules.nixos.gtnh = {
    imports = with inputs.gtnh-nix; [nixosModules.gtnh nixosModules."2.8.4"];
    programs.gtnh.enable = true;
    preservation = {
      preserveAt."/persistent".directories = ["/var/lib/gtnh"];
    };
  };
}
