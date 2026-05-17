{inputs, ...}: {
  flake.modules.homeManager.blender = {pkgs, ...}: {
    home.packages = [pkgs.blender];
  };

  flake.modules.nixos.blender = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.blender];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".config/blender"; mode = "0755";}];
    };
  };
}
