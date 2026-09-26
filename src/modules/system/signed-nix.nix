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
    {
      config,
      modules,
      lib,
      ...
    }:
    {
      imports = [
        inputs.self.modules.finix.secrets
        modules.nix-daemon
      ];

      age.secrets.deploy-key.rekeyFile = key;

      # `nix.settings` over there; the daemon owns its own configuration here.
      services.nix-daemon.settings.secret-key-files = [ config.age.secrets.deploy-key.path ];

      # Not in a VM, where the key does not exist - see the note in `secrets`. The daemon signs
      # every path it builds, so a missing key is not a weaker signature but a failed build, and
      # what it says is
      #
      #   error: opening file "/run/agenix/deploy-key": No such file or directory
      #
      # at the end of building something unrelated. Which read as a missing secret and is really
      # a daemon that cannot finish any build at all - home-manager's `installPackages` was the
      # first thing to notice.
      #
      # A machine thrown away after one boot has nobody to prove a closure's provenance to.
      virtualisation.vmVariant.services.nix-daemon.settings.secret-key-files = lib.mkForce [ ];
    };
}
