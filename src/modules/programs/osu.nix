{
  flake.modules.nixos.osu = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.package = [pkgs.osu-lazer-bin];
  };
}
