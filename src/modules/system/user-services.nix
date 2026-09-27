{ inputs, ... }:
{
  # What `systemd --user` is, assembled from finix's contract: a service manager of the user's
  # own, started by their session and stopped with it, so its units inherit the session's
  # environment rather than having to be told about it.
  #
  # Imported by every module that puts a daemon in the session, the way they used to import
  # `graphical-session` - which this replaces entirely. That module built the mechanism here:
  # system units running as the user, a oneshot polling for a wayland socket to order them
  # behind, and a wrapper each one ran under to discover where the display and the bus were. All
  # three were symptoms of a supervisor that started at boot and so could not have been given a
  # session, and none of them survive - the contract's `sessionLauncher` starts the tree from
  # inside the session instead. See `providers.services.users` in finix.
  #
  # dinit, because it is the only implementation that can be one user's supervisor today. finit
  # runs a unit as a given user, which is a different thing, and a finit that is not PID 1 with a
  # user's euid exits EX_NOPERM. Naming it here would be an eval error rather than a surprise,
  # which is the point of the contract asking.
  #
  # Two init systems on one machine, then: finit as PID 1 and a dinit per session. That is not
  # the duplication it looks like. PID 1 started before any session existed and will outlive it,
  # so it can hold neither the session's environment nor its lifetime, and those are the two
  # things a user tree needs. systemd reaches the same shape for the same reason - one
  # `systemd --user` beside PID 1 - and pays for sharing it across a user's sessions with
  # `import-environment`, which starting one per session is what avoids.
  flake.modules.finix.user-services = {
    imports = [ inputs.finix.nixosModules.dinit ];

    # naming it, not enabling it: `dinit.enable` would make dinit PID 1. This says only that
    # dinit is what supervises a user's tree, which is a question finit does not answer.
    providers.services.user.backend = "dinit";
  };
}
