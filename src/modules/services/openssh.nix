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

        # Where NixOS looks by default, plus the user module's key file - it
        # writes /etc/ssh/authorized_keys.d/<name> the way nixos does, and
        # sshd has to be told to read it.
        settings.AuthorizedKeysFile = [
          ".ssh/authorized_keys"
          "/etc/ssh/authorized_keys.d/%u"
        ];

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
      #
      # An attrset rather than the bare path, for the mode. preservation defaults a file to
      # 0644 and its tmpfiles `f` rule applies that mode to the file whether or not it created
      # it - so a bare path here does not merely leave a private key's mode unsaid, it forces it
      # world readable on every boot. sshd refuses such a key outright ("Permissions 0644 ...
      # are too open") and exits having loaded none, which is what this was doing.
      state.preserve.files = [
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          mode = "0600";
        }
      ];
    };
}
