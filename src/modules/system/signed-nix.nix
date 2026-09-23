{ inputs, ... }:
let
  # The key the deployer signs closures with, so a target will accept them.
  key = ../../secrets/master/nix-deploy/deploy-key.age;
in
{
  flake.modules.nixos.signed-nix =
    { config, ... }:
    {
      imports = [ inputs.self.modules.nixos.secrets ];

      age.secrets.deploy-key.rekeyFile = key;

      nix.settings.secret-key-files = [ config.age.secrets.deploy-key.path ];
    };

  flake.modules.finix.signed-nix =
    { config, modules, ... }:
    {
      imports = [
        inputs.self.modules.finix.secrets
        modules.nix-daemon
      ];

      age.secrets.deploy-key.rekeyFile = key;

      # `nix.settings` over there; the daemon owns its own configuration here.
      services.nix-daemon.settings.secret-key-files = [ config.age.secrets.deploy-key.path ];
    };
}
