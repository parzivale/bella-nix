{
  self,
  config,
  ...
}: {
  flake.modules.bella.signed-nix = {
    imports = with self.modules.bella; [nix secrets];
    nix.settings.secret-key-files = [config.age.secrets.deploy-key.path];
  };
}
