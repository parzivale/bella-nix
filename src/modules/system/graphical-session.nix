{ inputs, ... }:
{
  # What `graphical-session.target` and a user manager do under systemd, built out
  # of the service contract instead.
  #
  # A notification daemon, an idle watcher, a portal: each has to run inside the
  # session and needs the session's environment to find it. finix has no systemd
  # user session and `sessiond` is a session tracker rather than a supervisor, so
  # these are system units that run as the user - which buys what spawning them
  # from the compositor cannot: finit restarts one that dies, `requires` orders
  # them, and `initctl` can stop or start one by name.
  #
  # The cost of that trade is lifecycle. A user service is started at login and
  # stopped at logout; these are started at boot and wait for a session to appear.
  # On a machine with one user who is logged in automatically that distinction
  # does not arise. On a multi-user machine it would, and this would be the wrong
  # shape.
  flake.modules.finix.graphical-session =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.constants.username;
      runtimeDir = "/run/user/${toString config.constants.uid}";

      # Where the session records its bus address, there being no fixed one:
      # `dbus-run-session` mints an address per session and tells only its own
      # children. This is the same trick as ~/.dbus/session-bus, in the one place
      # that outlives neither the session nor a reboot.
      busAddressFile = "${runtimeDir}/dbus-session-address";

      # The socket name cannot be known ahead of time - niri takes whatever
      # `wayland-N` is free, through smithay's `new_auto`, and has no flag to
      # force one - so it is discovered rather than declared. Which is also why
      # this is a wrapper rather than each unit's `environment`: that is static
      # and this is not.
      sessionEnv = pkgs.writeShellScript "session-env" ''
        set -eu

        export XDG_RUNTIME_DIR=${runtimeDir}

        WAYLAND_DISPLAY=$(
          cd "$XDG_RUNTIME_DIR" &&
            ${pkgs.findutils}/bin/find . -maxdepth 1 -name 'wayland-*' -not -name '*.lock' \
              -printf '%f\n' | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/head -1
        )
        export WAYLAND_DISPLAY

        export DBUS_SESSION_BUS_ADDRESS="$(${pkgs.coreutils}/bin/cat ${busAddressFile})"

        exec "$@"
      '';

      # A session exists once both of those are there. Waiting for the socket alone
      # would not do: the address file is written by the session's own shell, and a
      # daemon reading it a moment early reads nothing.
      #
      # The deadline is enforced here rather than with the unit's `startTimeout`,
      # which finit cannot bound - it warns as much. Unbounded, a machine that never
      # reaches a session would leave this waiting forever and everything requiring
      # it stalled behind. Failing instead means the daemons do not start and the
      # log says why.
      waitForSession = pkgs.writeShellScript "wait-for-session" ''
        set -eu

        deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 120 ))

        while :; do
          if [ -e ${busAddressFile} ] &&
            ${pkgs.findutils}/bin/find ${runtimeDir} -maxdepth 1 -name 'wayland-*' -not -name '*.lock' \
              | ${pkgs.gnugrep}/bin/grep -q .; then
            exit 0
          fi

          if [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$deadline" ]; then
            echo "no graphical session after 120s: ${runtimeDir} has no wayland socket and no recorded bus address" >&2
            exit 1
          fi

          ${pkgs.coreutils}/bin/sleep 0.2
        done
      '';
    in
    {
      options.session = {
        command = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = ''
            What greetd runs: the session bus, the address recorded where units can
            read it, and then the compositor. The compositor module names this
            rather than building its own invocation.
          '';
          default = pkgs.writeShellScript "graphical-session" ''
            set -eu

            exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.runtimeShell} -c '
              printenv DBUS_SESSION_BUS_ADDRESS > ${busAddressFile}
              exec "$@"
            ' -- "$@"
          '';
        };

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
              };
            }
          );
        };
      };

      config = lib.mkIf (config.session.services != { }) {
        providers.services.units = {
          # A oneshot rather than a long-running unit: it finishes, and a finished
          # oneshot is what the units requiring it wait for.
          graphical-session = {
            description = "wait for the graphical session";

            requires = [ "multi-user" ];

            type.oneshot.command = toString waitForSession;

          };
        }
        // lib.mapAttrs (_: service: {
          inherit (service) description;

          requires = [ "graphical-session" ] ++ service.requires;

          inherit user;

          type.service.command = "${sessionEnv} ${lib.escapeShellArgs service.command}";
        }) config.session.services;
      };
    };
}
