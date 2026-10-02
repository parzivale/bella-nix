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
  flake.modules.finix.user-services =
    { config, ... }:
    let
      user = config.constants.username;
      hm = config.home-manager.users.${user};
    in
    {
      imports = [ inputs.finix.nixosModules.dinit ];

      # naming it, not enabling it: `dinit.enable` would make dinit PID 1. This says only that
      # dinit is what supervises a user's tree, which is a question finit does not answer.
      providers.services.user.backend = "dinit";

      # home-manager's session variables, which nothing here was reading.
      #
      # It writes them twice and neither copy reached the session. `home.sessionVariables`
      # becomes a shell file in profile.d, which only a shell sources;
      # `systemd.user.sessionVariables` becomes ~/.config/environment.d/10-home-manager.conf,
      # which exists on this machine, is correct, and is read by nobody - that file is systemd's
      # user manager's to import, and there is no systemd user manager here. So the variables
      # were present on disk, present in the evaluated configuration, and absent from every
      # process in the session.
      #
      # Which failed in a way that pointed at the wrong thing entirely. A Qt application started
      # from a terminal was themed and the same application started from a key binding was not,
      # because the terminal's shell had sourced profile.d and the compositor never had. It read
      # as the application ignoring stylix; the launcher it was started from was the variable.
      #
      # Both sources, because neither is a superset of the other and taking one leaves a
      # half-configured session:
      #
      #   systemd.user only   QML2_IMPORT_PATH, QT_PLUGIN_PATH
      #   home only           GTK2_RC_FILES, XCURSOR_SIZE, XCURSOR_THEME
      #   both                QT_QPA_PLATFORMTHEME, QT_STYLE_OVERRIDE, XDG_CONFIG_DIRS,
      #                       LOCALE_ARCHIVE_2_27 - and with equal values, so the merge order
      #                       below decides nothing
      #
      # The Qt pair is the trap. `home.sessionVariables` alone sets QT_QPA_PLATFORMTHEME and not
      # QT_PLUGIN_PATH, which names a platform theme Qt then cannot load, since qt5ct is itself
      # a plugin found along that path. A theme that fails to load is harder to recognise than
      # one that was never set.
      #
      # EDITOR, VISUAL and STARSHIP_CONFIG come along from the shell side. A session is a
      # reasonable place for them - something spawned from a key binding wanting $EDITOR gets
      # one - and excluding them would mean maintaining a list of what counts as graphical.
      providers.services.users.${user}.sessionVariables =
        hm.home.sessionVariables // hm.systemd.user.sessionVariables;
    };
}
