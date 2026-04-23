{
  flake.modules.nixos.matrix = {config, ...}: let
    domain = config.systemConstants.domain;
    matrix_domain = config.systemConstants.subDomains.matrix;
    homeserver = {
      address = "https://${matrix_domain}";
      inherit domain;
      software = "standard";
    };
    encryption = {
      allow = true;
      msc4190 = true;
      pickle_key = "$ENCRYPTION_PICKLE_KEY";
    };
  in {
    nixpkgs.overlays = [
      (_final: prev: {
        mautrix-meta = (prev.mautrix-meta.override {withGoolm = true;}).overrideAttrs (_old: {
          version = "26.04";
          src = prev.fetchFromGitHub {
            owner = "mautrix";
            repo = "meta";
            tag = "v0.2604.0";
            hash = "sha256-85dzr97TTU0OCTzFe1gJ7lohVilivRErrW+alnRc3sI=";
          };
          vendorHash = "sha256-SK7BGUOe85hDijNKoxhhDoHAd+KEcipEB1kJmUQ5zlc=";
          ldflags = ["-s" "-w" "-X" "main.Tag=v0.2604.0"];
        });
      })
    ];

    age.secrets.mautrix-instagram-env = {
      rekeyFile = ../../../../secrets/mautrix/mautrix-instagram.age;
      owner = "mautrix-meta-instagram";
    };
    age.secrets.mautrix-facebook-env = {
      rekeyFile = ../../../../secrets/mautrix/mautrix-facebook.age;
      owner = "mautrix-meta-facebook";
    };

    systemd.services.mautrix-meta-instagram-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };
    systemd.services.mautrix-meta-facebook-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-meta.instances = {
      instagram = {
        enable = true;
        environmentFile = config.age.secrets.mautrix-instagram-env.path;
        settings = {
          homeserver = homeserver;
          encryption = encryption;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-meta-instagram?host=/run/postgresql";
          };
          bridge.permissions."${domain}" = "user";
        };
      };
      facebook = {
        enable = true;
        environmentFile = config.age.secrets.mautrix-facebook-env.path;
        settings = {
          homeserver = homeserver;
          encryption = encryption;
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-meta-facebook?host=/run/postgresql";
          };
          bridge.permissions."${domain}" = "user";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-meta-instagram" "mautrix-meta-facebook"];
      ensureUsers = [
        {
          name = "mautrix-meta-instagram";
          ensureDBOwnership = true;
        }
        {
          name = "mautrix-meta-facebook";
          ensureDBOwnership = true;
        }
      ];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-meta-instagram";}
      {directory = "/var/lib/mautrix-meta-facebook";}
    ];
  };
}
