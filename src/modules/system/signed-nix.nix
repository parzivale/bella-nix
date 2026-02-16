{inputs, ...}: {
  flake.modules.nixos.signed-nix = {config, ...}: {
    imports = with inputs.self.modules.bella; [nix secrets];
    nix.settings.secret-key-files = [config.age.secrets.deploy-key.path];
  };
}
