{ inputs, ... }:
{
  flake.modules.homeManager.github =
    { pkgs, ... }:
    {
      programs.gh = {
        enable = true;
        settings.git_protocol = "ssh";
        extensions = [ pkgs.gh-dash ];
      };
    };

  flake.modules.nixos.github =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.github ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/gh";
            mode = "0700";
          }
        ];
      };
    };
}
