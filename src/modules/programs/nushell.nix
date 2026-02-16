{
  flake.modules.nixos.nushell = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.nushell.enable = true;
      home.shell.enableNushellIntegration = true;
    };
  };
}
