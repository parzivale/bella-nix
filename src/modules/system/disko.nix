# disko's option tree, for hosts whose disk layout is declared in a
# `disk-configuration.nix`. The same nixos module serves finix: it only
# declares `disko.devices` and derives `fileSystems` and the format scripts
# from it.
{ inputs, ... }:
{
  flake.modules.nixos.disko.imports = [ inputs.disko.nixosModules.disko ];
  flake.modules.finix.disko.imports = [ inputs.disko.nixosModules.disko ];
}
