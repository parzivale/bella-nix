{inputs, ...}: {
  flake.modules.homeManager.btop = _: {
    programs.btop.enable = true;
  };

  flake.modules.nixos.btop = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.btop];
  };
}
