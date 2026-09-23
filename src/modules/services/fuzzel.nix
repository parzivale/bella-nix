{ inputs, ... }:
{
  flake.modules.homeManager.fuzzel =
    { pkgs, ... }:
    {
      programs.fuzzel = {
        enable = true;
        settings.main.terminal = "${pkgs.wezterm}/bin/wezterm start --";
      };
    };

  flake.modules.nixos.fuzzel =
    { config, pkgs, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      state.keybinds."Mod+Space" = [ "${pkgs.fuzzel}/bin/fuzzel" ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.fuzzel ];
    };

}
