{
  flake.modules.nixos.openssh =
    {
      lib,
      config,
      ...
    }:
    {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = lib.mkDefault "no";
          AllowUsers = [ config.constants.username ];
        };

        generateHostKeys = true;

        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
    };

  flake.modules.finix.openssh =
    {
      lib,
      config,
      modules,
      ...
    }:
    {
      imports = [ modules.openssh ];

      services.openssh = {
        enable = true;

        # finix generates into /var/lib/sshd by default. Point it at the path the
        # nixos side uses, so a host key lives in the same place whichever class
        # evaluates the host - which keeps the preservation entry and the agenix
        # identity identical across both.
        hostKeyPath = "/etc/ssh/ssh_host_ed25519_key";

        # finix's settings are sshd_config keys with a freeform type, and
        # nixpkgs' are the same names, so the four carry over unchanged.
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = lib.mkDefault "no";
          AllowUsers = [ config.constants.username ];
        };
      };

      # No `generateHostKeys`/`hostKeys` here: finix generates the key in its own
      # unit, and `hostKeyPath` above is the whole of saying where.
      state.preserve.files = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };
}
