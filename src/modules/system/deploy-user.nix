_: {
  flake.modules.nixos.deploy-user =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      security.sudo.extraRules = [
        {
          users = [ user ];
          commands = [
            {
              command = "/nix/store/*/activate-rs *";
              options = [ "NOPASSWD" ];
            }
            {
              # A regex rather than a glob, because sudoers matches arguments as
              # one concatenated string and a `*` crosses word boundaries: the
              # old rule also permitted `rm <canary> /etc/anything`. `^` and `$`
              # anchor the whole argument string, so a second argument cannot
              # match. deploy-rs builds this path as
              # `deploy-rs-canary-{store hash}`, which is 32 base32 characters.
              command = "/run/current-system/sw/bin/rm ^/tmp/deploy-rs-canary-[a-z0-9]{32}$";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

  flake.modules.finix.deploy-user =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      # `providers.privileges` rather than `security.sudo`: finix has a contract
      # for "let this user run that as root", implemented by either sudo or
      # doas, and a host picks which.
      providers.privileges.rules = [
        {
          command = "/nix/store/*/activate-rs";
          args = [ "*" ];
          users = [ user ];
          requirePassword = false;
        }
        {
          # The path deploy-rs actually invokes: it sends bare `rm`, which
          # resolves through PATH to the system profile - not to a coreutils
          # store path. A rule naming the store path never matches, the
          # confirmation never arrives, and every deploy rolls back on the
          # magic-rollback timeout.
          command = "/run/current-system/sw/bin/rm";
          args = [ "^/tmp/deploy-rs-canary-[a-z0-9]{32}$" ];
          users = [ user ];
          requirePassword = false;
        }
      ];

      # Both of those are written for the sudo backend. The contract passes
      # `command` and `args` through verbatim, so a glob and a regex mean what
      # they mean to sudoers — and nothing to doas, which matches literally. A
      # finix host deploying with doas selected needs these rewritten, and will
      # find out by the rule not matching rather than by being told.
    };
}
