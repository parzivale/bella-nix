{ inputs, ... }:
{
  flake.modules.homeManager.lazygit = _: {
    programs.lazygit = {
      enable = true;
      settings.git.autoForwardBranches = "allBranches";
    };
  };

  flake.modules.nixos.lazygit =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.lazygit ];

      preservation = config.helpers.mkPreserve user {
        directories = [
          {
            directory = ".local/state/lazygit";
            mode = "0755";
          }
        ];
      };
    };
}
