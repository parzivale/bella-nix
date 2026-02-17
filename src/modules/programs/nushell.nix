{
  flake.modules.nixos.nushell = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.nushell = {
        enable = true;
        # configFile.source = ./configuration.nu;
        # extraEnv = builtins.readfile;
        plugins = [pkgs.bash-env-nushell];
      };
      home.shell.enableNushellIntegration = true;
    };
  };
}
