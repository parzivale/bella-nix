{ inputs, ... }:
{
  # The baseline for a host: what every machine of mine wants and which cannot be
  # said class-neutrally. It lives here rather than in `base` because base is
  # imported by both classes and everything here is spelled per class, and here
  # rather than in the flake's host wrapper because a host should say what it is
  # rather than be handed it.
  #
  # Both halves come to the same three things - an account, nix, and resolution -
  # plus, on finix, something to run scheduled work at all.
  flake.modules.nixos.system = {
    imports = with inputs.self.modules.nixos; [
      user
      nix
      systemd-resolved
    ];
  };

  flake.modules.finix.system =
    { modules, ... }:
    {
      imports =
        with inputs.self.modules.finix;
        [
          user
          nix
        ]
        ++ [
          modules.fcron
          modules.getty
          modules.sysklogd
        ];

      # `security.polkit` on the other side, where it is true on every host of mine.
      # Without it nothing can ask to do something as somebody else: 1Password's
      # policy file has no daemon to read it, and udisks and friends have no way to
      # authorise a mount. The agent that answers those questions is a session
      # service - see `niri`.
      services.polkit.enable = true;

      # What logind is on the other side, and needed for more than it sounds. A
      # compositor takes the display and the input devices through libseat, which
      # finds them through this; greetd's pam stack chooses `pam_elogind` once it is
      # on, and that is what creates /run/user/<uid>. Without it there is no runtime
      # directory at all - so no XDG_RUNTIME_DIR, nowhere for niri to put its wayland
      # socket, and nothing for the session units to wait for.
      #
      # Its module is in finix's always-loaded set, so this is only a switch. seatd
      # would serve the seat half alone; elogind serves both halves and is the
      # nearer thing to what the nixos hosts already have.
      services.elogind.enable = true;

      # A way in that is not the compositor. systemd hands a nixos host `getty@tty1`
      # without being asked; finix does not, and a machine whose only login is
      # greetd is one you cannot reach when the session fails to start - which is
      # exactly when reaching it matters. tty1 through tty6, and greetd's
      # `terminal.vt` is "next", so it takes the first free one above them.
      services.getty.enable = true;

      # Somewhere for output to go. finit can redirect a unit's stdout and stderr to
      # syslog through `logit`, and with no syslogd that redirection has nowhere to
      # arrive - where on nixos the journal is simply there. sysklogd rather than
      # rsyslog: this is a desktop that wants a log, not a relay.
      services.sysklogd.enable = true;

      # No resolution entry, where the nixos half names `systemd-resolved`:
      # `network` already arranges it through resolvconf on this side.

      # `providers.scheduler` has no backend by default, and a task defined with
      # none selected is a warning rather than an error - so the weekly
      # `nix-collect-garbage` that `nix` asks for was being defined and never run.
      #
      # fcron of the three finix offers, because it is the only one that can run a
      # task as a user as well as as root, and there is already a per-user periodic
      # task in this configuration: modprobed-db samples loaded modules every six
      # hours. anacron is root-only, and cron cannot catch a job up at all.
      #
      # What fcron costs is the named intervals' meaning. The backend maps them to
      # fcron's `@` form, which counts "1 week of fcron execution" and delays the
      # job at each startup by the time the machine spent off - so `weekly` on a
      # desktop that sleeps overnight is nearer three weeks of wall clock. nixos'
      # timer is `Persistent`, which catches up instead. fcron can say that too,
      # with its `%` periodical form; the backend does not use it.
      services.fcron.enable = true;
    };
}
