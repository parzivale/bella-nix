{moduleWithSystem, ...}: {
  flake.modules.nixos.nushell = moduleWithSystem (
    {inputs', ...}: {config, ...}: let
      user = config.systemConstants.username;
    in {
      home-manager.users.${user} = {
        programs.nushell = {
          enable = true;
          # configFile.source = ./configuration.nu;
          # extraEnv = builtins.readfile;
          plugins = [inputs'.bash-env-nushell.packages.default];
        };
        home.shell.enableNushellIntegration = true;
      };
    }
  );
}
