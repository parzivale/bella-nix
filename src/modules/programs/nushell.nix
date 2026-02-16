{
  flake.modules.nixos.nushell = {config, ...}: let
    user = config.vars.username;
  in {
    home-manager.users.${user} = {
      home.shell.enableNushellIntegration = true;
    };
  };
}
