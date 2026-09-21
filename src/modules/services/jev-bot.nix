{ inputs, ... }:
{
  flake.modules.nixos.jev-bot =
    { config, ... }:
    {
      imports = [ inputs.jev-bot.nixosModules.default ];

      age.secrets = {
        jev-bot-discord-token.rekeyFile = ../../secrets/master/jev-bot/discord-token.age;
        jev-bot-typesafe-key.rekeyFile = ../../secrets/master/jev-bot/typesafe-key.age;
      };

      services.jev-bot = {
        enable = true;
        tokenFile = config.age.secrets.jev-bot-discord-token.path;
        apiKeyFile = config.age.secrets.jev-bot-typesafe-key.path;
      };

      # Both paths are read through systemd LoadCredential, which happens as
      # root before the unit drops to its DynamicUser — so the secrets can keep
      # agenix's default root-only ownership. They only exist under /run once
      # agenix has installed them, hence the ordering.
      systemd.services.jev-bot = {
        after = [ "agenix-install-secrets.service" ];
        requires = [ "agenix-install-secrets.service" ];
      };
    };
}
