{ inputs, ... }:
{
  flake.modules.nixos.pipewire = {
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };

  # community-modules' pipewire rather than finix's, and the difference is
  # `configPackages`: a package dropping its own pipewire and wireplumber
  # configuration into the search path, which is how asahi-audio delivers the
  # filters and routing an Apple Silicon machine's speakers need. finix's module
  # has a generic `packages` and no wireplumber module carrying the idea at all.
  #
  # They cannot both be imported - each declares `programs.pipewire.package` - and
  # finix's wireplumber imports finix's pipewire, so this side takes community's
  # pair and neither of finix's.
  flake.modules.finix.pipewire =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      runtimeDir = "/run/user/${toString config.constants.uid}";

      # The mixer topology, when a machine has said what its is - an Apple Silicon one does,
      # through `nixos-apple-silicon`, naming alsa-ucm-conf-asahi. pipewire and wireplumber
      # read it themselves, so it belongs on their units rather than anywhere broader: finix
      # renders `environment.variables` into /etc/profile.d, which a login shell sources and a
      # unit never does, and sourcing that from a service wrapper would hand every session
      # daemon every system variable to fix one.
      #
      # This is also what nixos-apple-silicon does on nixos - it sets the variable on the
      # pipewire and wireplumber units as well as in `environment.variables`, which is the
      # evidence that the general one does not reach a service.
      environment = lib.optionalAttrs (config.environment.variables ? ALSA_CONFIG_UCM2) {
        inherit (config.environment.variables) ALSA_CONFIG_UCM2;
      };
    in
    {
      imports = [
        inputs.community-modules.nixosModules.pipewire
        inputs.self.modules.finix.graphical-session
        # finix leaves device management off; the rules this lays down go nowhere
        # without it. No nixos counterpart - see `udev`.
        inputs.self.modules.finix.udev
      ];

      programs.pipewire.alsa = {
        enable = true;
        support32Bit = true;
      };

      # What that module's README says to do - run the three by hand from the
      # compositor's autostart, with `sleep 0.5` between them, noting that "this
      # would normally be handled in service conditions". There are service
      # conditions here, so this is those.
      #
      # `waitFor.socket` is what replaces the sleep, and it is a stronger statement
      # than the sleep was: it connects, where a path check would pass on a socket
      # that exists from `bind` and is not yet listening. So wireplumber and
      # pipewire-pulse start when pipewire will actually answer them rather than
      # when it has probably got going.
      state.session.services = {
        pipewire = {
          description = "multimedia service";
          command = [ "${config.programs.pipewire.package}/bin/pipewire" ];
          readiness.waitFor.socket.path = "${runtimeDir}/pipewire-0";
          inherit environment;
        };

        wireplumber = {
          description = "pipewire session manager";
          command = [ "${pkgs.wireplumber}/bin/wireplumber" ];
          requires = [ "pipewire" ];
          inherit environment;
        };

        pipewire-pulse = {
          description = "pulseaudio server on pipewire";
          command = [ "${config.programs.pipewire.package}/bin/pipewire-pulse" ];
          requires = [ "pipewire" ];
          readiness.waitFor.socket.path = "${runtimeDir}/pulse/native";
        };
      };
    };
}
