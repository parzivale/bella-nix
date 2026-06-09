{ inputs, ... }:
{
  flake.modules.homeManager.fuzzel =
    { pkgs, ... }:
    {
      programs.niri.settings.binds = {
        "Mod+Space".action.spawn = [ "${pkgs.fuzzel}/bin/fuzzel" ];
      };
      programs.fuzzel = {
        enable = true;
        settings.main.terminal = "${pkgs.wezterm}/bin/wezterm start --";
      };
    };

  flake.modules.nixos.fuzzel =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.fuzzel ];
    };
}
