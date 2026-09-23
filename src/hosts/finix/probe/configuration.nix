_: {
  # Deliberately near-empty: this host exists so the finix evaluation path is
  # exercised by `nix flake check` rather than only by hand. It is what proves
  # `modules.generic.base` stays class-neutral — the moment something in base
  # reaches for a NixOS option, this stops evaluating.
  networking.hostName = "probe";
}
