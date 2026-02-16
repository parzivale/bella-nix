{
  flake.modules.nixos.yazi = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.yazi = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
