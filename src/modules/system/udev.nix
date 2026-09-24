_: {
  # Only a finix module, and deliberately: on nixos udev is systemd-udevd, which
  # is there whether or not anything says so, and a nixos twin of this would be
  # an empty module inviting imports that mean nothing. Anything needing device
  # management imports this in its finix branch and nothing in its nixos one -
  # which reads as an asymmetry, and is one, because the two classes genuinely
  # differ here.
  #
  # eudev rather than mdevd or keventd, which finix also offers. Those pair with
  # libudev-zero, and libudev-zero has no rules engine and no hwdb - so a rule's
  # permissions carry over and its *properties* cannot, no matter what is
  # written for the other backend. udisks2 and pipewire are the two libudev-zero
  # names as depending on those properties, and both are in this stack.
  flake.modules.finix.udev = {
    services.udev.enable = true;
  };
}
