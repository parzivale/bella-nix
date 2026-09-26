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

                joinSession = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = ''
                    Whether this daemon must be a member of the login session, rather than
                    merely having its environment.

                    Most session daemons need only the compositor's socket and the session bus,
                    which the wrapper provides. A few ask logind which session they are in -
                    an authentication agent has to, because the thing it authenticates is a
                    session - and that question is answered by the process's cgroup, not by any
                    variable. A daemon the supervisor started at boot is in the supervisor's
                    cgroup and logind says it belongs to no session at all:

                      polkit-gnome-1-WARNING: Unable to determine the session we are in:
                      No session for pid 6744

                    With this set, the unit starts as root, moves itself into the session's
                    cgroup, and only then drops to the user - so it and everything it forks are
                    members. The cost is that the unit briefly runs privileged, which is why it
                    is opt-in and why the default is to do the ordinary thing.
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
