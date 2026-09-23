{ inputs, ... }:
let
  # The same list either way — each of these publishes both classes, so the
  # profile is the set of names and the class is which namespace they come
  # from.
  programs = [
    "lazygit"
    "yazi"
    "git"
    "nh"
    "ssh"
    "helix"
    "starship"
    "nushell"
    "btop"
    "tldr"
  ];

  from = class: map (name: inputs.self.modules.${class}.${name}) programs;
in
{
  flake.modules.nixos.cli.imports = from "nixos";
  flake.modules.finix.cli.imports = from "finix";
}
