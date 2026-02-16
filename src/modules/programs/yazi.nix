{
  flake.modules.yazi.base = {config, ...}: let
    user = config.systemConstants.username;
  in {
    hoe-manager.users.${user} = {
      programs.yazi = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
