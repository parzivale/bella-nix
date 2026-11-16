# Apple Silicon support for finix hosts. Hardware specifics - `hardware.asahi.*`, firmware,
# facter - stay with the host; this is only the module tree and the packages it builds from.
#
# finix only: a nixos host would import nixos-apple-silicon without the compatibility layer
# below, so it would be a different module.
{ inputs, ... }:
{
  flake.modules.finix.apple-silicon = {
    imports = [
      # The asahi module tree, which carries no class stamp so finix can import it, plus the
      # compatibility layer which declares the option paths it writes to and forwards the ones
      # with somewhere to go. That layer is also what turns asahi's
      # `systemd.packages = [ speakersafetyd ]` into `services.speakersafetyd.enable` - the
      # speaker protection is not optional on this hardware, so it asserts rather than dropping
      # the unit quietly.
      inputs.nixos-apple-silicon.nixosModules.default
      inputs.community-modules.nixosModules.apple-silicon
    ];

    nixpkgs.overlays = [ inputs.nixos-apple-silicon.overlays.default ];
  };
}
