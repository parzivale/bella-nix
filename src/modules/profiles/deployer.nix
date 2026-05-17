{
  flake.modules.nixos.deployer = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    nix.settings.system-features = [
      "yubikey"
    ];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = "develop"; mode = "0755";}];
    };
  };
}
