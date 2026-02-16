{
  flake.modules.nixos.nushell = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      home.shell.enableNushellIntegration = true;
    };
  };
}
