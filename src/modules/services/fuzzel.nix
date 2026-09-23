{ inputs, ... }:
let
  fuzzel =
    homeManager:
    { config, pkgs, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ homeManager ];

      state.keybinds."Mod+Space" = [ "${pkgs.fuzzel}/bin/fuzzel" ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.fuzzel ];
    };
in
{
  flake.modules.homeManager.fuzzel =
    { pkgs, ... }:
    {
      programs.fuzzel = {
        enable = true;
        settings.main.terminal = "${pkgs.wezterm}/bin/wezterm start --";
      };
    };

  flake.modules.nixos.fuzzel = fuzzel inputs.self.modules.nixos.home-manager;
  flake.modules.finix.fuzzel = fuzzel inputs.self.modules.finix.home-manager;
}
