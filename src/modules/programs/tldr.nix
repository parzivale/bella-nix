{
  flake.modules.nixos.tldr = {config, pkgs, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.tlrc];
  };
}
