{
  # Daemons that belong to the graphical session, declared without naming a
  # compositor or a supervisor - the third of these contracts, beside
  # `state.preserve` and `state.keybinds`, and written for the same reason.
  #
  # A notification daemon, an idle watcher, a portal, a sound server: each has to
  # run inside the session and needs the session's environment to find it, so none
  # can start before the session exists. A module knows which daemon it ships and
  # what to run; what starts it is the host's business. Under systemd that is a
  # user service per daemon ordered after `graphical-session.target`; where there
  # is no systemd user session it is whatever the class arranges.
  #
  # Only finix implements it today - see `graphical-session` there. The nixos side
  # still writes home-manager units per module, which is the duplication this would
  # remove if it ever grew a second implementation.
  flake.modules.generic.session =
    { lib, ... }:
    {
      options.state.session = {
        services = lib.mkOption {
          default = { };
          description = ''
            Daemons that belong to the graphical session, each becoming a unit which
            runs as the user once the session is up.
          '';
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                description = lib.mkOption {
                  type = lib.types.str;
                  description = "A short human-readable description of this daemon.";
                };

                command = lib.mkOption {
                  type = with lib.types; listOf str;
                  description = ''
                    The program and its arguments. An argument vector rather than a shell
                    string, so a path with a space in it is one argument.
                  '';
                };

                requires = lib.mkOption {
                  type = with lib.types; listOf str;
                  default = [ ];
                  description = ''
                    Further units this one waits for, on top of the session itself. This
                    is where "after the notification daemon" is said.
                  '';
                };

                readiness = lib.mkOption {
                  type = lib.types.anything;
                  default = [ { fork = { }; } ];
                  description = ''
                    How this daemon reports that it is up, passed through to the unit. The
                    default is the contract's: ready once the process is spawned.

                    Worth setting for anything another unit waits on. `waitFor.socket`
                    connects rather than checking that a path exists, which is the difference
                    between ordering and a `sleep`.
                  '';
                };

                environment = lib.mkOption {
                  type = with lib.types; attrsOf str;
                  default = { };
                  description = ''
                    Environment variables for this daemon, on top of the session's own.

                    The session wrapper supplies where the display and the bus are; this is
                    for what a particular daemon needs beyond that - `ALSA_CONFIG_UCM2`
                    naming a machine's mixer topology, say.
                  '';
                };
              };
            }
          );
        };
      };
    };
}
