{ inputs, ... }:
let
  # The same module for nixos and finix; `class` only picks which home-manager it imports.
  module =
    class:
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.${class}.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.git ];
    };
in
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

  flake.modules.nixos.git = module "nixos";
  flake.modules.finix.git = module "finix";
}
