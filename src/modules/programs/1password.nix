{
  flake.modules.nixos._1password = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [config.programs._1password.package];
    programs._1password.enable = true;
  };
}
