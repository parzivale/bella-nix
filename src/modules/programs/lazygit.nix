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
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.lazygit ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/state/lazygit";
            mode = "0755";
          }
        ];
      };
    };
}
