{inputs, ...}: {
  flake.modules.homeManager.fractal = {pkgs, ...}: {
    home.packages = [pkgs.fractal];
  };

  flake.modules.nixos.fractal = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.fractal];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/fractal";
          mode = "0700";
        }
      ];
    };
  };
}
