{ inputs, ... }:
{
  # What every finix host of mine wants, and the counterpart to `nixos`: a login
  # account, nix daemon settings, and something to run scheduled work. It lives
  # here rather than in `base` because base is class-neutral, and here rather than
  # in the flake's host wrapper because a host should say what it is rather than be
  # handed it.
  #
  # No DNS entry, where the nixos one names `systemd-resolved`: on this side
  # `network` already arranges resolution through resolvconf.
  flake.modules.finix.finix =
    { modules, ... }:
    {
      imports =
        with inputs.self.modules.finix;
        [
          user
          nix
        ]
        ++ [ modules.fcron ];

      # `providers.scheduler` has no backend by default, and a task defined with
      # none selected is a warning rather than an error - so the weekly
      # `nix-collect-garbage` that `nix` asks for was being defined and never run.
      #
      # fcron of the three finix offers, because it is the only one that can run a
      # task as a user as well as as root, and there is already a per-user periodic
      # task in this configuration: modprobed-db samples loaded modules every six
      # hours. anacron is root-only, and cron cannot catch up a job at all.
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
