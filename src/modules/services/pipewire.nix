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
        inputs.self.modules.finix.user-services
        # finix leaves device management off; the rules this lays down go nowhere
        # without it. No nixos counterpart - see `udev`.
        inputs.self.modules.finix.udev
      ];

      # `enable`, which this had never set - and that is the whole of why these speakers sound
      # wrong.
      #
      # The module was imported for `configPackages` and then left switched off, so its entire
      # `config` block - which is `mkIf cfg.enable` - never ran. Nothing wrote /etc/pipewire or
      # /etc/wireplumber, and the units below ran a pipewire with no configuration directory at
      # all. It starts perfectly well like that, which is why nothing said anything: the graph
      # comes up, the card is found, audio plays. What is missing is every filter, so what the
      # amps get is the stream itself:
      #
      #   Sinks:   * 56. Built-in Audio Speakers   [vol: 0.30]
      #   Filters:
      #   Streams:   77. Twilight  85. output_FR > Speakers:playback_FR [active]
      #
      # `Filters:` empty, and the stream wired straight to the raw ALSA sink. On this hardware
      # the DSP is not a refinement, it is the crossover: asahi-audio's filter chain is what
      # splits the signal and keeps full-range content away from the tweeters, and it publishes
      # its own sink for everything to play into instead. Without it there was nothing between
      # a stream and four drivers.
      #
      # `configPackages` on both halves, because asahi-audio ships configuration for both and
      # they do different jobs: share/pipewire carries the filter chains, share/wireplumber the
      # routing and policy which hides the raw sink behind them. Setting one and not the other
      # gets filters nothing routes through.
      #
      # The plugin paths come along without being said here. The chains are LV2 and LADSPA -
      # bankstown for the bass, the convolver for the IRs - and the module reads
      # `passthru.requiredLv2Packages` off each config package and exports LV2_PATH and
      # LADSPA_PATH through `security.pam.environment`. Which does reach these units, unlike
      # `environment.variables`: pam_env sets it on the session, and the supervisor is started
      # inside the session, so it inherits. Tested rather than assumed - LANG comes from the
      # same file and is in the running pipewire's environ, where ALSA_CONFIG_UCM2 is not and
      # has to be named on the units above.
      programs.pipewire = {
        enable = true;

        alsa = {
          enable = true;
          support32Bit = true;
        };

        configPackages = [ pkgs.asahi-audio ];

        wireplumber = {
          enable = true;
          configPackages = [ pkgs.asahi-audio ];
        };
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
      #
      # None of the three waits for the compositor, and that is a change. They used to, because
      # the module they were declared through gated everything it emitted on a wayland socket
      # appearing - so audio could not start until a compositor had, and a machine that never
      # reached one had no sound server either. Nothing here needs a display: `XDG_RUNTIME_DIR`
      # is where the sockets go and that is fixed, so being in the session at all is the whole
      # requirement, and being in this tree is that.
      providers.services.users.${config.constants.username}.units = {
        pipewire = {
          description = "multimedia service";
          type.service = {
            command = "${config.programs.pipewire.package}/bin/pipewire";
            readiness.waitFor.socket.path = "${runtimeDir}/pipewire-0";
          };
          inherit environment;
        };

        wireplumber = {
          description = "pipewire session manager";
          type.service.command = "${pkgs.wireplumber}/bin/wireplumber";
          requires = [ "pipewire" ];
          inherit environment;
        };

        pipewire-pulse = {
          description = "pulseaudio server on pipewire";
          type.service = {
            command = "${config.programs.pipewire.package}/bin/pipewire-pulse";
            readiness.waitFor.socket.path = "${runtimeDir}/pulse/native";
          };
          requires = [ "pipewire" ];
        };
      };
    };
}
