{inputs, ...}: {
  flake.modules.homeManager.nh = _: {
    programs.nh.enable = true;
  };

  flake.modules.nixos.nh = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.nh];
  };
}
