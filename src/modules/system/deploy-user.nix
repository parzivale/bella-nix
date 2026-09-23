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
}
