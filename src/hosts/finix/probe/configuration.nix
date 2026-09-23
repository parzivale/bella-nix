_: {
  # Deliberately near-empty: this host exists so the finix evaluation path is
  # exercised by `nix flake check` rather than only by hand. It is what proves
  # `modules.generic.base` stays class-neutral — the moment something in base
  # reaches for a NixOS option, this stops evaluating.
  networking.hostName = "probe";

  # What this machine is. The flake says which nixpkgs to build that for.
  nixpkgs.hostPlatform = "x86_64-linux";

  # And what runs it. `providers.services` renders units into whichever backend
  # is selected, and selecting one is how a machine gets a pid 1 at all.
  finit.enable = true;
}
