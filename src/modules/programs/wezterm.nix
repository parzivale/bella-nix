{
  flake.modules.nixos.wezterm = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.wezterm.enable = true;
    };
  };
}
