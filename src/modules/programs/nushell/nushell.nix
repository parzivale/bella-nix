{
  flake.modules.nixos.nushell = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.nushell = {
        enable = true;
        extraConfig = builtins.readFile ./configuration.nu;
        # extraEnv = builtins.readFile ./env.nu;
      };
      home.shell.enableNushellIntegration = true;
    };
  };
}
