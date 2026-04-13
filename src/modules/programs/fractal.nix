{
  flake.modules.nixos.fractal = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.fractal];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/fractal";
          mode = "0700";
        }
        {
          directory = ".config/fractal";
          mode = "0700";
        }
      ];
    };
  };
}
