{
  # State worth surviving a wipe, collected independently of whatever persists
  # it. Modules contribute here; a host implements it — or doesn't, in which
  # case the attrset is inert. `services/preservation.nix` is the NixOS
  # implementation, and a finix host is free to write its own against the same
  # contract.
  flake.modules.generic.preserve =
    { lib, ... }:
    let
      # Entries are either a bare path or an attrset carrying per-entry
      # settings (mode, how, inInitrd, ...). What those fields mean belongs to
      # the implementer, so keep them opaque here.
      entries = lib.mkOption {
        type = with lib.types; listOf (either str attrs);
        default = [ ];
      };
    in
    {
      options.state.preserve = {
        directories = entries;
        files = entries;

        # The units which read or write the state above, named by whichever module declared
        # that state - it is the one which knows both the path and what uses it. An
        # implementation which sets the state up while units are already running (finix with no
        # initrd) orders these after it; one which does it before any unit starts ignores this.
        units = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
        };

        users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                directories = entries;
                files = entries;
              };
            }
          );
          default = { };
        };
      };
    };
}
