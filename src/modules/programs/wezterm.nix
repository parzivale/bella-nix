{
  flake.modules.nixos.wezterm = {config, ...}: let
    user = config.vars.username;
  in {
    home-manager.users.${user} = {
      programs.wezterm.enable = true;
    };
  };
}
