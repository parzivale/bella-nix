{moduleWithSystem, ...}: {
  flake.modules.nixos.nushell = moduleWithSystem (
    {inputs', ...}: {
      config,
      pkgs,
      ...
    }: let
      user = config.systemConstants.username;
    in {
      home-manager.users.${user} = {config, ...}: {
        programs = {
          lazygit.enableNushellIntegration = true;
          yazi.enableNushellIntegration = true;
          zoxide.enableNushellIntegration = true;
          starship.enableNushellIntegration = true;
          nushell = {
            enable = true;
            configFile.source = ./configuration.nu;
            extraEnv = ''
              def bash-env[
                path?: string
              ] {
                let path_args = if $path != null {
                  [($path | path expand)]
                } else {
                  []
                }

                let input_str = $in | default "" | str join "\n"
                let raw = $input_str | ${pkgs.bash-env-json}/bin/bash-env-json  ...($path_args) | complete
                let raw_json = $raw.stdout | from json

                let error = $raw_json | get -o error
                if $error != null {
                  error make { msg: $error }
                } else if $raw.exit_code != 0 {
                  error make { msg: $"unexpected failure from bash-env-json ($raw.stderr)" }
                }

                $raw_json.env
              }

              load-env (bash-env "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh")
            '';
            settings = {
              show_banner = false;
            };
          };
        };
        home.shell.enableNushellIntegration = true;
      };
    }
  );
}
