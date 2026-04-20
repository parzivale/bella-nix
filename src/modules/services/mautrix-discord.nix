{
  flake.modules.nixos.mautrix-discord = {config, ...}: let
    domain = config.systemConstants.domain;
  in {
    nixpkgs.overlays = [
      (final: prev: {
        mautrix-discord = prev.mautrix-discord.override {
          olm = prev.olm.overrideAttrs (_: {meta.knownVulnerabilities = [];});
        };
      })
    ];

    age.secrets.mautrix-discord-env = {
      rekeyFile = ../../secrets/mautrix/mautrix-discord.age;
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
          address = "https://matrix.${domain}";
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
