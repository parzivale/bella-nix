{ inputs, ... }:
{
  flake.modules.homeManager.git = _: {
    home.file.".cargo/config.toml".text = ''
      [net]
      git-fetch-with-cli = true
    '';

    programs.git = {
      enable = true;
      settings = {
        url."git@github.com:".insteadOf = "https://github.com/";
        user = {
          name = "parzivale";
          email = "zeus@theolivers.org";
        };
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
    };
  };

  flake.modules.nixos.git =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.git ];
    };

  flake.modules.finix.git =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.git ];
    };
}
