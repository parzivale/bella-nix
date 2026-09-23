{ inputs, ... }:
{
  # Sole owner of chaotic-nyx. Importing `inputs.chaotic.nixosModules.default`
  # from two places double-declares its options — an input's module value has no
  # key for the module system to dedup on, so each import site is a fresh
  # anonymous module. Going through this one, which `addInfo` keys by name, makes
  # it importable from anywhere as often as needed.
  flake.modules.nixos.chaotic = {
    imports = [ inputs.chaotic.nixosModules.default ];
  };
}
