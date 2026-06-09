{ inputs, ... }:
{
  flake.modules.nixos.signed-nix =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [ secrets ];
      age.secrets.deploy-key.rekeyFile = ../../secrets/nix-deploy/deploy-key.age;

      nix.settings.secret-key-files = [ config.age.secrets.deploy-key.path ];
    };
}
