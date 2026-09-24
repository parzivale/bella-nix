{ inputs, ... }:
let
  # The same list either way - each of these publishes both classes, so the
  # profile is the set of names and the class is which namespace they come
  # from.
  modules = [
    "openssh"
    "tailscale"
    "preservation"
    "deploy-user"
  ];

  from = class: map (name: inputs.self.modules.${class}.${name}) modules;
in
{
  flake.modules.nixos.deployable.imports = from "nixos";
  flake.modules.finix.deployable.imports = from "finix";
}
