{
  # Things to run when the graphical session starts, declared without naming a
  # compositor - the companion to `state.keybinds`, and there for the same
  # reason.
  #
  # A notification daemon, an idle watcher, a portal: each is a process that has
  # to be running inside the session, needs the session's environment to find it
  # - WAYLAND_DISPLAY, DBUS_SESSION_BUS_ADDRESS - and so cannot be started before
  # the session exists. Under systemd that is `graphical-session.target` and a
  # user service per daemon. Where there is no systemd user session, the thing
  # that creates the environment is the compositor, so the compositor is what
  # starts them; which compositor is the host's business, so modules say what to
  # run and it reads this.
  #
  # What is lost against a user service is worth being clear about: nothing
  # restarts these if they die, nothing orders them against each other, and
  # nothing can be told to stop or reload one. A daemon that needs any of that
  # wants a real supervisor rather than an entry here.
  flake.modules.generic.startup =
    { lib, ... }:
    {
      options.state.startup = lib.mkOption {
        type = with lib.types; listOf (listOf str);
        default = [ ];
        example = lib.literalExpression ''
          [
            [ "mako" ]
            [ "poweralertd" "-s" ]
          ]
        '';
        description = ''
          Commands to run once the graphical session is up, as the program and its
          arguments.

          Argument vectors rather than shell strings, so that a path with a space
          in it is one argument and nothing has to be quoted. A command that
          genuinely wants shell syntax can say so by spawning a shell.
        '';
      };
    };
}
