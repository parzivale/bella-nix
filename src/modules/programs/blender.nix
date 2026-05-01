{
  flake.modules.nixos.blender = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.blender];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".config/blender";
          mode = "0755";
        }
      ];
    };
  };
}
