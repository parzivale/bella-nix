{ inputs, ... }:
{
  flake.modules.homeManager.direnv = _: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # enableNushellIntegration = true;
    };
  };

  flake.modules.nixos.direnv =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.direnv ];

      preservation = config.helpers.mkPreserve user {
        directories = [ ".local/share/direnv" ];
      };
    };
}
