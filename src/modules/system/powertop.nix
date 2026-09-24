_: {
  flake.modules.nixos.powertop = {
    powerManagement.powertop.enable = true;
  };

  # finix keeps this under `services`, with tlp and thermald, rather than in a
  # `powerManagement` namespace of its own. A host opting out says
  # `services.powertop.enable = lib.mkForce false` where the nixos one says
  # `powerManagement.powertop.enable`.
  flake.modules.finix.powertop =
    { modules, ... }:
    {
      imports = [ modules.powertop ];
      services.powertop.enable = true;
    };
}
