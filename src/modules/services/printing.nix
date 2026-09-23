{ inputs, ... }:
{
  flake.modules.nixos.printing = {
    services.printing = {
      enable = true;

      # cups-browsed discovers printers over the network and adds them behind
      # your back; avahi already advertises what this host shares.
      browsed.enable = false;

      drivers = [ ];
    };
  };

  flake.modules.finix.printing = {
    imports = [ inputs.community-modules.nixosModules.cups ];

    # `services.printing` over there, `services.cups` here - the community
    # module is named for the daemon rather than the task.
    #
    # No `browsed.enable = false` to match: that module runs cupsd and nothing
    # else, so there is no cups-browsed to turn off.
    services.cups = {
      enable = true;
      drivers = [ ];
    };
  };
}
