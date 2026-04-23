{
  flake.modules.nixos.matrix = {config, ...}: let
    domain = config.systemConstants.domain;
    matrix_domain = config.systemConstants.subDomains.matrix;
  in {
    nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];

    nixpkgs.overlays = [
      (_final: prev: {
        mautrix-discord = prev.mautrix-discord.override {
          olm = prev.olm.overrideAttrs (_: {meta.knownVulnerabilities = [];});
        };
      })
    ];

    age.secrets.mautrix-discord-env = {
      rekeyFile = ../../../../secrets/mautrix/mautrix-discord.age;
      owner = "mautrix-discord";
    };

    systemd.services.mautrix-discord-registration = {
      after = ["agenix-install-secrets.service"];
      wants = ["agenix-install-secrets.service"];
    };

    services.mautrix-discord = {
      enable = true;
      environmentFile = config.age.secrets.mautrix-discord-env.path;
      settings = {
        homeserver = {
          address = "https://${matrix_domain}";
          inherit domain;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-discord?host=/run/postgresql";
        };
        bridge = {
          permissions."${domain}" = "user";
          encryption = {
            allow = true;
            msc4190 = true;
            pickle_key = "$ENCRYPTION_PICKLE_KEY";
          };
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["mautrix-discord"];
      ensureUsers = [
        {
          name = "mautrix-discord";
          ensureDBOwnership = true;
        }
      ];
    };

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/mautrix-discord";}
    ];
  };
}
