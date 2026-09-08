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
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.github ];

      preservation = config.helpers.mkPreserve user {
        directories = [
          {
            directory = ".config/gh";
            mode = "0700";
          }
        ];
      };
    };
}
