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

  # The packages without the module. chaotic's nixos module brings its cache,
  # its registry entry and its kernel machinery, none of which finix can take;
  # the overlay is what a package like proton-cachyos actually needs, and
  # `nixpkgs.overlays` is there to take it.
  #
  # The cache is the thing worth noticing: building a chaotic package without
  # nyx-cache.chaotic.cx means building it, and these are not small.
  flake.modules.finix.chaotic = {
    nixpkgs.overlays = [ inputs.chaotic.overlays.default ];
  };
}
