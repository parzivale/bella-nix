{
  flake.modules.nixos.btop = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.btop.enable = true;
  };
}
