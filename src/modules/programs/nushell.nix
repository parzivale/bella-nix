{
  flake.modules.nixos.nushell = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.nushell = {
        enable = true;
        configFile.source = ./configuration.nu;
      };
      home.shell.enableNushellIntegration = true;
    };
  };
}
