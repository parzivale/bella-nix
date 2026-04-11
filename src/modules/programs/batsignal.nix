{
  flake.modules.nixos.batsignal = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.services.batsignal.enable = true;
  };
}
