_: {
  flake.modules.nixos.deploy-user =
    { config, ... }:
    let
      user = config.systemConstants.username;
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
              command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
