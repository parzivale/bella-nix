{
  flake.modules.nixos.systemConstants = {lib, ...}: {
    options.systemConstants = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = {};
    };

    config.systemConstants = import ../../../vars.nix;
  };
}
